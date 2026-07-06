"""
Enhanced Response Node — dengan TOKEN STREAMING + content tags.

Perubahan dari versi lama:
1. Stream LLM output token-by-token via callback (TokenEvent)
2. Format content dengan tags: <plan>, <reasoning>, <action>, <reflection>
   agar Flutter ChatBubble multi-tag parser bisa render cards
3. Include structured metadata di final answer
4. Auto-collapse tags jika data tidak ada (jangan render empty cards)
"""
import inspect
import json
import logging
from typing import Any

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.agent.state import AgentState
from app.llm import get_llm

logger = logging.getLogger(__name__)


RESPONSE_SYSTEM_PROMPT = """
# LAPISAN 1 — PERSONA
(Sisipkan PERSONA CARD dari bagian 1 di sini.)

# LAPISAN 2 — PERAN
Kamu sedang menyusun JAWABAN FINAL yang akan dibaca langsung oleh user.
Semua tag internal (<plan>, <reasoning>, <action>, <reflection>, <think>)
ditangani oleh layer di luar teksmu — jangan pernah menuliskan tag itu
sendiri di dalam isi jawaban.

# GROUNDING CONTRACT
- Setiap angka, label, atau klaim faktual di jawabanmu harus berasal
  dari tool result yang ada di context. Kalau sebuah data tidak ada
  di tool result, katakan "belum ada info soal itu" — jangan mengisi
  dengan tebakan yang terdengar masuk akal.
- Kalau reflection menandai missing_aspects yang tidak berhasil
  dipenuhi (info_sufficient tetap false setelah max_reflections),
  jawabanmu HARUS secara eksplisit dan jujur menyebutkan keterbatasan
  itu ke user — misal "saya belum menemukan referensi terkini soal X,
  tapi berikut yang saya punya dari sumber lokal...". Jangan berpura-pura
  info lengkap.

# GAYA MENTOR (rujuk PERSONA CARD untuk kapan Socratic vs direktif)
- Kalau mode direktif: jawab lengkap dulu, baru tutup dengan satu
  pertanyaan reflektif yang mengundang user berpikir lanjut (bukan
  pertanyaan basa-basi seperti "ada yang bisa dibantu lagi?").
- Kalau mode Socratic: buka dengan SATU pertanyaan pemandu yang
  spesifik ke miskonsepsi user, baru berikan penjelasan penuh setelah
  atau berdampingan dengan pertanyaan itu — jangan menahan seluruh
  jawaban hanya demi Socratic, itu bisa terasa manipulatif kalau user
  butuh jawaban cepat.

# FORMAT PREDIKSI (jika ada hasil predictive_tool)
## 📊 Hasil Prediksi Kelulusan
**Prediksi:** [Lulus/Tidak Lulus]
**Confidence:** [XX%] ([interpretasi singkat])
**Data:** [n] field eksplisit + [m] field disintesis

### 🎯 Analisis Learning-Scientist
[1-3 kalimat yang menafsirkan angka dengan prinsip belajar yang relevan
— misal cognitive load, spaced repetition — HANYA kalau relevan dengan
angka yang ada, jangan menempel jargon tanpa alasan]

### ⚠️ Risk Factors
- ...

### 💡 Rekomendasi (actionable, spesifik ke angka user)
- ...

### 🔍 Field yang Disintesis (transparansi)
- field: value (alasan singkat kenapa disintesis)

## FORMAT RAG (jika ada citations)
📚 **Referensi:**
1. [Judul] — ringkasan singkat kenapa ini relevan ke pertanyaan user
2. ...

## FORMAT WEB (jika ada web results)
🌐 **Info Terkini:**
- [Judul](url): ringkasan singkat + tanggal/relevansi waktu kalau ada

# LARANGAN
- Jangan mengarang angka di luar hasil tool.
- Jangan menampilkan tag XML/internal apapun.
- Jangan menjanjikan kelulusan sebagai kepastian.
- Jangan memberi label diagnosis psikologis pada user; kalau narasi
  user menunjukkan distres, validasi dan sarankan bicara ke konselor
  kampus, jangan mendiagnosis.
- Tutup jawaban dengan insight yang ditambatkan ke data user, bukan
  kalimat motivasi generik tanpa dasar.
"""


async def _emit(state: AgentState, event: dict[str, Any]) -> None:
    """Send event via callback."""
    callback = getattr(state, "state_update_callback", None)
    if callback:
        try:
            if inspect.iscoroutinefunction(callback):
                await callback(event)
            else:
                callback(event)
        except Exception as e:
            logger.debug("Callback emit failed: %s", e)


def _build_plan_summary(state: AgentState) -> str:
    """Build <plan> tag content dari execution plan."""
    if not state.plan:
        return ""

    lines = []
    for step in state.plan:
        status_icon = {
            "pending": "⏳",
            "running": "🔄",
            "done": "✅",
            "skipped": "⏭️",
            "failed": "❌",
        }.get(step.status, "❓")
        deps = f" (depends: {step.depends_on})" if step.depends_on else ""
        lines.append(f"{status_icon} Step {step.step_id}: [{step.tool}] {step.description}{deps}")

    return "\n".join(lines) if lines else ""


def _build_reasoning_summary(state: AgentState) -> str:
    """Build <reasoning> tag content dari supervisor scratchpad."""
    reasoning_parts = []
    for entry in state.scratchpad:
        if entry.get("role") != "assistant":
            continue
        preview = entry.get("reasoning_preview", "")
        if preview and len(preview) > 20:
            reasoning_parts.append(preview)

    if not reasoning_parts:
        return ""

    # Ambil 2 reasoning terbaru
    return "\n\n".join(reasoning_parts[-2:])


def _build_action_summary(state: AgentState) -> str:
    """Build <action> tag content dari tool_call_log."""
    if not state.tool_call_log:
        return ""

    # Group by parallel_group
    groups: dict[str, list[dict]] = {}
    sequential: list[dict] = []

    for log in state.tool_call_log:
        pg = log.get("parallel_group")
        if pg:
            groups.setdefault(pg, []).append(log)
        else:
            sequential.append(log)

    lines = []
    for pg, logs in groups.items():
        tool_names = [l["tool"] for l in logs]
        lines.append(f"⚡ Parallel ({len(logs)}x): {', '.join(tool_names)}")

    for log in sequential:
        lines.append(f"→ {log['tool']}")

    return "\n".join(lines) if lines else ""


def _build_reflection_summary(state: AgentState) -> str:
    """Build <reflection> tag content."""
    if not state.reflection:
        return ""

    r = state.reflection
    parts = [f"Quality: {r.quality_score:.0%}"]
    if r.missing_aspects:
        parts.append(f"Missing: {', '.join(r.missing_aspects)}")
    parts.append(f"Action: {r.next_action}")
    parts.append(r.reason)
    return " | ".join(parts)


def _build_tagged_prefix(state: AgentState) -> str:
    """Build tagged content prefix untuk ChatBubble multi-tag parser.

    Hanya include tags yang punya content (non-empty).
    """
    parts = []

    plan_text = _build_plan_summary(state)
    if plan_text:
        reasoning = ""
        # Coba ambil reasoning dari planner (first PlanGeneratedEvent reasoning)
        # Untuk simplicity, kosongkan di sini
        parts.append(f'<plan reasoning="{reasoning}">\n{plan_text}\n</plan>\n\n')

    reasoning_text = _build_reasoning_summary(state)
    if reasoning_text:
        parts.append(f"<reasoning>\n{reasoning_text}\n</reasoning>\n\n")

    action_text = _build_action_summary(state)
    if action_text:
        # Ambil parallel_group dari tool_call_log pertama yang punya
        parallel_group = ""
        for log in state.tool_call_log:
            if log.get("parallel_group"):
                parallel_group = log["parallel_group"]
                break
        if parallel_group:
            parts.append(f'<action group="{parallel_group}">\n{action_text}\n</action>\n\n')
        else:
            parts.append(f"<action>\n{action_text}\n</action>\n\n")

    reflection_text = _build_reflection_summary(state)
    if reflection_text:
        quality = state.reflection.quality_score if state.reflection else 0.0
        missing = ", ".join(state.reflection.missing_aspects) if state.reflection else ""
        parts.append(
            f'<reflection quality="{quality:.2f}" missing="{missing}">\n'
            f"{reflection_text}\n</reflection>\n\n"
        )

    return "".join(parts)


async def response_node(state: AgentState) -> dict:
    """Generate final response dengan token streaming."""
    await _emit(state, {
        "type": "state_update",
        "node": "respond",
        "status": "started",
        "iteration": state.iteration,
    })

    logger.info("Response node: generating final answer")

    # Build context dari scratchpad
    llm = get_llm()
    messages: list = [SystemMessage(content=RESPONSE_SYSTEM_PROMPT)]

    # Replay scratchpad untuk context
    for m in state.scratchpad:
        role = m.get("role", "")
        content = m.get("content", "")
        if role == "user":
            messages.append(HumanMessage(content=content))
        elif role == "assistant":
            messages.append(AIMessage(content=content if isinstance(content, str) else str(content)))
        elif role == "tool":
            # Include tool results sebagai human context
            messages.append(HumanMessage(
                content=f"[Tool: {m.get('name', 'unknown')}]\n{content}"
            ))

    # Original user message
    if not any(isinstance(m, HumanMessage) for m in messages):
        messages.append(HumanMessage(content=state.user_message))

    # Generate response dengan streaming
    full_response = ""
    token_index = 0

    try:
        # Coba streaming
        stream = llm.astream(messages)
        async for chunk in stream:
            chunk_text = chunk.content if isinstance(chunk.content, str) else str(chunk.content)
            if not chunk_text:
                continue

            # Emit token event
            await _emit(state, {
                "type": "token",
                "content": chunk_text,
                "index": token_index,
            })
            token_index += 1
            full_response += chunk_text

    except AttributeError:
        # Fallback: LLM tidak support streaming, gunakan ainvoke
        logger.warning("LLM doesn't support streaming, falling back to ainvoke")
        result = await llm.ainvoke(messages)
        full_response = result.content if isinstance(result.content, str) else str(result.content)

        # Emit sebagai single token
        await _emit(state, {
            "type": "token",
            "content": full_response,
            "index": 0,
        })

    except Exception as e:
        logger.exception("Response generation failed: %s", e)
        full_response = (
            "Maaf, terjadi kesalahan saat membuat respons. "
            "Silakan coba kirim pesan Anda lagi."
        )
        await _emit(state, {
            "type": "token",
            "content": full_response,
            "index": 0,
        })

    # Build tagged prefix + actual response
    tagged_prefix = _build_tagged_prefix(state)
    final_content = tagged_prefix + full_response if tagged_prefix else full_response

    logger.info(
        "Response node done: %d tokens, %d chars total (prefix: %d chars)",
        token_index,
        len(final_content),
        len(tagged_prefix),
    )

    await _emit(state, {
        "type": "state_update",
        "node": "respond",
        "status": "completed",
        "iteration": state.iteration,
    })

    return {
        "final_answer": final_content,
    }
