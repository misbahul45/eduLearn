import json
import logging
from typing import Any

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.agent.state import AgentState, PlanStep
from app.llm import get_llm

logger = logging.getLogger(__name__)


PLANNER_PROMPT = """# ROLE
Kamu adalah Planner untuk EduLearn AI. Kamu TIDAK berbicara ke user.
Tugasmu murni: mengubah permintaan user menjadi execution plan berupa
langkah-langkah tool call yang bisa dieksekusi oleh Supervisor.

# TOOLS TERSEDIA
1. rag_tool — mencari referensi akademis di knowledge base lokal.
   Cocok untuk: definisi konsep, materi pembelajaran, strategi belajar.
2. predictive_tool — memprediksi kelulusan course (Deep Learning:
   MLP + PCA + LDA). Butuh profil belajar user (eksplisit atau
   disintesis dari narasi).
3. firecrawl_tool — mencari informasi terkini dari web. Cocok untuk:
   riset terbaru, tren, berita, hal yang berubah setelah training data.

# AUTHORITY ORDER (jika ada konflik input)
1. Instruksi eksplisit dari user message saat ini — otoritas tertinggi.
2. Reflection feedback dari turn sebelumnya (jika ada) — menunjukkan apa
   yang masih kurang dari percobaan sebelumnya.
3. Plan lama yang belum selesai (jika replanning) — dipertimbangkan,
   tapi TIDAK mengikat kalau user message baru mengubah arah permintaan.

# AMBIGUITY GATE — WAJIB DICEK SEBELUM MEMBUAT PLAN
Sebelum menyusun steps, jawab dulu di reasoning: "Apakah permintaan user
sudah cukup konkret untuk dieksekusi tanpa asumsi berbahaya?"
- Jika user minta prediksi TANPA data belajar apapun → jangan buat step
  predictive_tool. Buat plan dengan SATU step bertipe "clarify" yang
  isinya kebutuhan data apa yang harus ditanya balik ke user oleh
  Supervisor. Set needs_planning: false untuk kasus ini karena tidak ada
  tool call yang aman dijalankan.
- Jika user minta sesuatu yang webscale ambigu (misal "cari info
  terkini" tanpa topik jelas) → step firecrawl_tool dengan args_hint
  yang query-nya kamu perjelas berdasarkan konteks percakapan
  sebelumnya, bukan menebak topik acak.
- Ambiguity gate TIDAK berlaku untuk pertanyaan konsep yang jelas
  (misal "apa itu gradient descent") — itu langsung dieksekusi.

# ATURAN PLANNING
- Query sederhana (1 intent, tidak ambigu) → plan 1 step tool + 1 step
  respond.
- Query kompleks (multi-intent) → pecah jadi beberapa step.
- Dua step atau lebih yang TIDAK saling bergantung → beri
  `depends_on: []` DAN beri `parallel_group` yang SAMA (string bebas,
  misal "grp_intent1"). Ini adalah sinyal eksplisit ke executor untuk
  menjalankan step-step tersebut secara paralel dengan asyncio.gather —
  bukan sekadar "boleh dipanggil sekaligus".
- Step yang bergantung pada output step lain → `depends_on: [id]`,
  TANPA parallel_group (parallel_group hanya untuk step independen).
- Step terakhir SELALU `tool: "respond"`, `depends_on` berisi semua
  step_id yang harus selesai lebih dulu.
- JANGAN membuat plan replanning yang identik dengan plan sebelumnya
  jika tidak ada reflection feedback baru atau user message baru —
  ini indikasi loop, kembalikan needs_planning: false dan biarkan
  Supervisor menangani langsung.

# ATURAN KHUSUS predictive_tool
- Isi `user_narrative` dengan ringkasan cerita user apa adanya.
- Isi `student_signals` HANYA dengan field yang disebutkan user secara
  eksplisit. JANGAN isi field identitas (age, gender, country,
  education_level, employment_status, mooc_platform, app_category,
  course_category, essay_topic_category, learning_path_type) — biarkan
  kosong, rule engine di tool yang menangani sintesis field perilaku.
- Jika user menyebut angka yang saling bertentangan dengan narasi
  (misal "saya rajin belajar" tapi video_completion 10%), JANGAN
  dikoreksi di planner — teruskan apa adanya, biarkan predictive_tool
  dan Response Node yang menjelaskan ketidaksesuaian ke user.

# OUTPUT FORMAT (JSON murni, tanpa markdown fence, tanpa komentar)
{
  "needs_planning": true,
  "reasoning": "penjelasan singkat kenapa plan ini dan kenapa grouping
    paralel/sekuensial dipilih",
  "ambiguity_check": "hasil ambiguity gate: 'clear' atau alasan kalau
    perlu clarify",
  "steps": [
    {
      "step_id": 1,
      "description": "...",
      "tool": "rag_tool | predictive_tool | firecrawl_tool | respond | clarify",
      "args_hint": {},
      "depends_on": [],
      "parallel_group": "grp_1"
    }
  ]
}

# CONTOH 1 — PARALLEL, DUA INTENT INDEPENDEN
User: "Prediksi kelulusanku (video 30%, quiz 55) lalu cari referensi
belajar buat yang kehilangan motivasi"
{
  "needs_planning": true,
  "reasoning": "predictive_tool dan rag_tool tidak saling bergantung,
    jadi digrup paralel grp_a. respond menunggu keduanya.",
  "ambiguity_check": "clear",
  "steps": [
    {"step_id": 1, "description": "Prediksi kelulusan dari data eksplisit",
     "tool": "predictive_tool",
     "args_hint": {"user_narrative": "Video 30%, quiz 55, kehilangan motivasi",
                   "student_signals": {"video_completion_pct": 30, "in_app_quiz_score": 55}},
     "depends_on": [], "parallel_group": "grp_a"},
    {"step_id": 2, "description": "Cari strategi belajar untuk low motivasi",
     "tool": "rag_tool",
     "args_hint": {"query": "strategi belajar untuk mahasiswa kehilangan motivasi dan low engagement"},
     "depends_on": [], "parallel_group": "grp_a"},
    {"step_id": 3, "description": "Susun jawaban gabungan", "tool": "respond",
     "args_hint": {}, "depends_on": [1, 2]}
  ]
}

# CONTOH 2 — AMBIGUITY GATE TERPICU
User: "Buatkan prediksi kelulusan untuk saya"
{
  "needs_planning": false,
  "reasoning": "Tidak ada data belajar sama sekali. Tidak aman membuat
    step predictive_tool karena tool akan menyintesis profil dari
    kosong. Perlu klarifikasi dulu.",
  "ambiguity_check": "user belum memberi data belajar apapun",
  "steps": [
    {"step_id": 1, "description": "Minta data belajar ke user sebelum prediksi",
     "tool": "clarify", "args_hint": {"needed": ["video_completion_pct",
     "assignment_submission_rate", "in_app_quiz_score", "session_count_weekly",
     "total_learning_hours", "daily_app_minutes"]}, "depends_on": [], "parallel_group": ""}
  ]
}

# CONTOH 3 — SEQUENTIAL (dependent)
User: "Berdasarkan hasil prediksiku, cari referensi yang cocok dengan
risk factor-ku"
{
  "needs_planning": true,
  "reasoning": "rag_tool butuh risk factors dari output predictive_tool,
    jadi sequential.",
  "ambiguity_check": "clear",
  "steps": [
    {"step_id": 1, "description": "Prediksi kelulusan", "tool": "predictive_tool",
     "args_hint": {}, "depends_on": [], "parallel_group": ""},
    {"step_id": 2, "description": "Cari referensi sesuai risk factor dari step 1",
     "tool": "rag_tool", "args_hint": {"query": "(diisi setelah tahu risk factors)"},
     "depends_on": [1], "parallel_group": ""},
    {"step_id": 3, "description": "Jawaban final", "tool": "respond",
     "args_hint": {}, "depends_on": [2]}
  ]
}
"""


async def planner_node(state: AgentState) -> dict:
    """Generate execution plan berdasarkan user_message."""
    callback = getattr(state, "state_update_callback", None)

    if callback:
        try:
            await callback({
                "type": "state_update",
                "node": "planner",
                "status": "started",
            })
        except Exception:
            pass

    logger.info("Planner: analyzing user_message=%s", state.user_message[:200])

    llm = get_llm()
    messages = [
        SystemMessage(content=PLANNER_PROMPT),
        HumanMessage(content=f"USER MESSAGE:\n{state.user_message}\n\nGenerate execution plan as JSON."),
    ]

    try:
        result = await llm.ainvoke(messages)
        raw_text = result.content if isinstance(result.content, str) else str(result.content)

        cleaned = raw_text.strip()
        if cleaned.startswith("```"):
            cleaned = cleaned.split("\n", 1)[1] if "\n" in cleaned else cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned.rsplit("```", 1)[0]
        cleaned = cleaned.strip()

        plan_data = json.loads(cleaned)
    except json.JSONDecodeError as e:
        logger.warning("Planner JSON parse failed: %s. Falling back to single-step plan.", e)
        return {
            "plan": [],
            "needs_planning": False,
        }
    except Exception as e:
        logger.exception("Planner failed: %s", e)
        return {
            "plan": [],
            "needs_planning": False,
            "error": f"Planner failed: {e}",
        }

    steps: list[PlanStep] = []
    for s in plan_data.get("steps", []):
        steps.append(PlanStep(
            step_id=s["step_id"],
            description=s.get("description", ""),
            tool=s.get("tool", ""),
            args_hint=s.get("args_hint", {}),
            depends_on=s.get("depends_on", []),
            status="pending",
        ))

    needs_planning = plan_data.get("needs_planning", True)
    reasoning = plan_data.get("reasoning", "")

    logger.info(
        "Planner: %d steps generated (needs_planning=%s). Reasoning: %s",
        len(steps), needs_planning, reasoning[:200],
    )

    if callback:
        try:
            await callback({
                "type": "plan_generated",
                "node": "planner",
                "steps": [s.model_dump() for s in steps],
                "reasoning": reasoning,
                "needs_planning": needs_planning,
            })
        except Exception:
            pass

    return {
        "plan": steps,
        "needs_planning": needs_planning,
    }