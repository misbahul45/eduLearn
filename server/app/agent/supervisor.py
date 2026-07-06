import inspect
import json
import logging
from typing import Any

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage

from app.agent.state import AgentState
from app.agent.tools import firecrawl_tool, predictive_tool, rag_tool
from app.llm import get_llm

logger = logging.getLogger(__name__)

from app.agent.prompts import build_system_prompt


async def _emit(state: AgentState, event: dict[str, Any]) -> None:
    callback = getattr(state, "state_update_callback", None)
    if callback:
        try:
            if inspect.iscoroutinefunction(callback):
                await callback(event)
            else:
                callback(event)
        except Exception:
            pass


def _build_plan_context(state: AgentState) -> str:
    if not state.plan:
        return ""

    lines = ["\n\n# EXECUTION PLAN (dari Planner)"]
    for step in state.plan:
        status_icon = {
            "pending": "⏳",
            "running": "🔄",
            "done": "✅",
            "skipped": "⏭️",
            "failed": "❌",
        }.get(step.status, "❓")
        deps = f" (depends_on: {step.depends_on})" if step.depends_on else ""
        lines.append(
            f"  {status_icon} Step {step.step_id}: [{step.tool}] {step.description}{deps}"
        )

    pending = state.pending_steps()
    if pending:
        lines.append("\n# STEPS YANG SIAP DIEKSEKUSI SEKARANG (parallel)")
        for s in pending:
            args_str = json.dumps(s.args_hint, ensure_ascii=False)[:200]
            lines.append(f"  → Step {s.step_id}: {s.tool} | args_hint={args_str}")
        lines.append(
            "\n⚠️ PANGGIL SEMUA tools dari pending steps INI DALAM SATU TURN "
            "(emit multiple tool_calls) agar dieksekusi PARALLEL."
        )
    else:
        lines.append("\n✅ Semua step sudah selesai. Siapkan jawaban final.")

    return "\n".join(lines)


def _build_reflection_context(state: AgentState) -> str:
    if not state.reflection:
        return ""

    r = state.reflection
    lines = ["\n\n# REFLECTION FEEDBACK (dari Reflector)"]
    lines.append(f"Info sufficient: {r.info_sufficient}")
    lines.append(f"Plan completed: {r.plan_completed}")
    lines.append(f"Quality score: {r.quality_score:.2f}")
    lines.append(f"Next action: {r.next_action}")
    lines.append(f"Reason: {r.reason}")
    if r.missing_aspects:
        lines.append("Missing aspects:")
        for m in r.missing_aspects:
            lines.append(f"  - {m}")
        lines.append(
            "\n⚠️ ASPEK DI ATAS BELUM TERCOVER. Pertimbangkan panggil tool lagi "
            "untuk melengkapi informasi sebelum menjawab."
        )
    return "\n".join(lines)


async def supervisor_node(state: AgentState) -> dict:
    await _emit(state, {
        "type": "state_update",
        "node": "supervisor",
        "status": "started",
        "iteration": state.iteration,
    })

    logger.info("Supervisor reasoning iteration=%d", state.iteration)
    llm = get_llm()
    bound_llm = llm.bind_tools([rag_tool, predictive_tool, firecrawl_tool])

    plan_ctx = _build_plan_context(state)
    reflection_ctx = _build_reflection_context(state)
    system_content = build_system_prompt() + plan_ctx + reflection_ctx

    messages: list = [SystemMessage(content=system_content)]

    for m in state.scratchpad:
        role = m.get("role", "")
        content = m.get("content", "")
        if role == "user":
            messages.append(HumanMessage(content=content))
        elif role == "assistant":
            tc_list = m.get("tool_calls") or []
            if not isinstance(tc_list, list):
                tc_list = []
            messages.append(AIMessage(
                content=content,
                tool_calls=tc_list,
            ))
        elif role == "tool":
            tool_call_id = m.get("tool_call_id", "")
            if not tool_call_id:
                continue
            messages.append(ToolMessage(
                content=content[:4000] if isinstance(content, str) else str(content)[:4000],
                tool_call_id=tool_call_id,
                name=m.get("name", ""),
            ))

    if not any(isinstance(m, HumanMessage) for m in messages):
        messages.append(HumanMessage(content=state.user_message))

    try:
        result = await bound_llm.ainvoke(messages)
    except Exception as e:
        logger.error("LLM invocation failed: %s", e)
        await _emit(state, {
            "type": "error",
            "node": "supervisor",
            "message": f"LLM call failed: {e}",
            "fatal": True,
        })
        return {
            "scratchpad": state.scratchpad,
            "iteration": state.iteration,
            "error": str(e),
            "final_answer": "Maaf, terjadi kesalahan pada sistem. Silakan coba lagi.",
        }

    reasoning_preview = ""
    if isinstance(result.content, str) and result.content.strip():
        reasoning_preview = result.content[:300]
        logger.info("Supervisor reasoning: %s", reasoning_preview)
    elif result.tool_calls:
        tool_names = [tc.get("name", "") for tc in result.tool_calls]
        reasoning_preview = f"(no text, direct tool_calls: {tool_names})"
        logger.info("Supervisor emitted %d tool_calls: %s", len(result.tool_calls), tool_names)

    new_scratchpad = state.scratchpad.copy()
    new_scratchpad.append({
        "role": "assistant",
        "content": result.content if isinstance(result.content, str) else str(result.content),
        "tool_calls": result.tool_calls if result.tool_calls else [],
        "reasoning_preview": reasoning_preview,
    })

    await _emit(state, {
        "type": "state_update",
        "node": "supervisor",
        "status": "completed",
        "iteration": state.iteration + 1,
        "tool_calls_count": len(result.tool_calls) if result.tool_calls else 0,
        "reasoning_preview": reasoning_preview,
    })

    return {
        "scratchpad": new_scratchpad,
        "iteration": state.iteration + 1,
    }