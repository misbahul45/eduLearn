import inspect
import json
import logging
from typing import Any

from langchain_core.messages import HumanMessage, SystemMessage

from app.agent.state import AgentState, ReflectionResult
from app.llm import get_llm

logger = logging.getLogger(__name__)


REFLECTOR_PROMPT = """Kamu adalah **Reflector** untuk EduLearn AI.

Tugasmu: evaluasi apakah informasi yang sudah terkumpul cukup untuk menjawab permintaan user secara memadai.

# KONTEKS
- User message: {user_message}
- Execution plan: {plan_status}
- Tools yang sudah dipanggil: {tools_called}
- Hasil prediksi tersedia: {has_prediction}
- Jumlah citations RAG: {n_citations}
- Jumlah web search results: {n_web}

# CRITERIA EVALUASI
1. **info_sufficient**: Apakah info yang terkumpul bisa menjawab pertanyaan user?
2. **plan_completed**: Apakah semua step plan sudah dieksekusi?
3. **missing_aspects**: List aspek yang belum tercover (kosongkan jika semua sudah cukup)
4. **quality_score**: 0.0-1.0, seberapa yakin kamu jawaban akan berkualitas
5. **next_action**: "iterate" jika perlu panggil tool lagi, "respond" jika sudah cukup

# ATURAN
- Jika user minta prediksi TAPI tidak ada hasil prediksi → next_action="iterate", missing_aspects=["prediction"]
- Jika user minta referensi TAPI citations=0 → next_action="iterate", missing_aspects=["rag_references"]
- Jika user minta info terkini TAPI web_results=0 → next_action="iterate", missing_aspects=["web_results"]
- Jika semua sudah ada dan relevan → next_action="respond"
- JANGAN iterate lebih dari 2x untuk aspek yang sama (hindari loop)

# OUTPUT (JSON murni, tanpa markdown fence)
{{
  "info_sufficient": true|false,
  "plan_completed": true|false,
  "missing_aspects": ["..."],
  "next_action": "iterate"|"respond",
  "reason": "...",
  "quality_score": 0.85
}}
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
            logger.debug("Reflector emit failed: %s", e)


async def reflector_node(state: AgentState) -> dict:
    """Evaluasi apakah perlu iterasi lagi atau cukup untuk respond."""
    await _emit(state, {
        "type": "state_update",
        "node": "reflector",
        "status": "started",
        "reflection_count": state.reflection_count + 1,
    })

    if state.reflection_count >= state.max_reflections:
        logger.info("Reflector: max_reflections reached, forcing respond")
        reflection = ReflectionResult(
            info_sufficient=True,
            plan_completed=True,
            missing_aspects=[],
            next_action="respond",
            reason="Max reflections reached, force respond",
            quality_score=0.6,
        )
        await _emit_full_reflection(state, reflection)
        return {
            "reflection": reflection,
            "reflection_count": state.reflection_count + 1,
        }

    tools_called = [log["tool"] for log in state.tool_call_log]
    plan_status = []
    for step in state.plan:
        plan_status.append(f"Step {step.step_id} [{step.tool}]: {step.status}")
    plan_str = "\n".join(plan_status) if plan_status else "(no plan)"

    prompt = REFLECTOR_PROMPT.format(
        user_message=state.user_message[:500],
        plan_status=plan_str,
        tools_called=", ".join(tools_called) if tools_called else "(none)",
        has_prediction="yes" if state.prediction else "no",
        n_citations=len(state.citations),
        n_web=len(state.web_search_results),
    )

    llm = get_llm()
    messages = [
        SystemMessage(content="You are a strict but fair evaluator. Output JSON only."),
        HumanMessage(content=prompt),
    ]

    try:
        result = await llm.ainvoke(messages)
        raw = result.content if isinstance(result.content, str) else str(result.content)

        cleaned = raw.strip()
        if cleaned.startswith("```"):
            cleaned = cleaned.split("\n", 1)[1] if "\n" in cleaned else cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned.rsplit("```", 1)[0]
        cleaned = cleaned.strip()

        reflection_data = json.loads(cleaned)
        reflection = ReflectionResult(
            info_sufficient=reflection_data.get("info_sufficient", False),
            plan_completed=reflection_data.get("plan_completed", False),
            missing_aspects=reflection_data.get("missing_aspects", []),
            next_action=reflection_data.get("next_action", "respond"),
            reason=reflection_data.get("reason", ""),
            quality_score=float(reflection_data.get("quality_score", 0.5)),
        )
    except Exception as e:
        logger.warning("Reflector failed: %s. Defaulting to respond.", e)
        reflection = ReflectionResult(
            info_sufficient=True,
            plan_completed=True,
            missing_aspects=[],
            next_action="respond",
            reason=f"Reflector error, default to respond: {e}",
            quality_score=0.5,
        )

    logger.info(
        "Reflector: next_action=%s, quality=%.2f, info_sufficient=%s, plan_completed=%s, missing=%s",
        reflection.next_action,
        reflection.quality_score,
        reflection.info_sufficient,
        reflection.plan_completed,
        reflection.missing_aspects,
    )

    await _emit_full_reflection(state, reflection)

    return {
        "reflection": reflection,
        "reflection_count": state.reflection_count + 1,
    }


async def _emit_full_reflection(state: AgentState, reflection: ReflectionResult) -> None:
    """Emit reflection event dengan SEMUA field yang Flutter expect."""
    await _emit(state, {
        "type": "reflection",
        "node": "reflector",
        "info_sufficient": reflection.info_sufficient,
        "plan_completed": reflection.plan_completed,
        "missing_aspects": reflection.missing_aspects,
        "next_action": reflection.next_action,
        "reason": reflection.reason,
        "quality_score": reflection.quality_score,
    })