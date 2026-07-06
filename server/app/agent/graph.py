import logging
from typing import Callable

from langgraph.graph import END, StateGraph
from typing import Callable, Optional

from app.agent.state import AgentState
from app.agent.planner import planner_node
from app.agent.supervisor import supervisor_node
from app.agent.tools.tools_node import tools_node
from app.agent.reflector import reflector_node
from app.agent.response_node import response_node
import uuid
logger = logging.getLogger(__name__)


def route_after_planner(state: AgentState) -> str:
    """Setelah planner, langsung ke supervisor (selalu)."""
    return "supervisor"


def route_after_supervisor(state: AgentState) -> str:
    """Routing setelah supervisor berpikir."""
    # Force respond jika iterasi melebihi max
    if state.iteration >= state.max_iterations:
        logger.info("Routing: max_iterations reached → respond")
        return "respond"

    if state.error:
        return "respond"

    last_sr = state.scratchpad[-1] if state.scratchpad else {}
    tcs = last_sr.get("tool_calls", [])

    if tcs:
        # Supervisor emit tool calls → execute
        logger.info("Routing: supervisor emitted %d tool_calls → tools", len(tcs))
        return "tools"

    # Tidak ada tool calls. Cek apakah perlu refleksi.
    # Refleksi hanya jika: belum pernah reflect ATAU ada plan yang belum complete
    if state.reflection_count == 0 and not state.is_plan_complete():
        logger.info("Routing: no tool_calls + plan incomplete → reflector")
        return "reflector"

    # Jika sudah pernah reflect dan next_action=iterate → balik ke supervisor (tapi tanpa tool_calls, dead end)
    # Maka kita force respond
    logger.info("Routing: no tool_calls + plan complete/already reflected → respond")
    return "respond"


def route_after_reflector(state: AgentState) -> str:
    """Routing setelah reflector evaluasi."""
    if not state.reflection:
        return "respond"

    if state.reflection.next_action == "iterate" and state.iteration < state.max_iterations:
        logger.info("Reflector: iterate → supervisor")
        return "supervisor"

    logger.info("Reflector: respond")
    return "respond"


def create_graph() -> StateGraph:
    """Build enhanced graph dengan planner + parallel tools + reflector."""
    builder = StateGraph(AgentState)

    builder.add_node("planner", planner_node)
    builder.add_node("supervisor", supervisor_node)
    builder.add_node("tools", tools_node)
    builder.add_node("reflector", reflector_node)
    builder.add_node("respond", response_node)

    # Entry point: planner
    builder.set_entry_point("planner")

    # Edges
    builder.add_edge("planner", "supervisor")  # planner → supervisor (always)

    builder.add_conditional_edges("supervisor", route_after_supervisor, {
        "tools": "tools",
        "reflector": "reflector",
        "respond": "respond",
    })

    # Tools always back to supervisor
    builder.add_edge("tools", "supervisor")

    # Reflector conditional: bisa balik ke supervisor (iterate) atau ke respond
    builder.add_conditional_edges("reflector", route_after_reflector, {
        "supervisor": "supervisor",
        "respond": "respond",
    })

    # Respond = END
    builder.add_edge("respond", END)

    return builder.compile()


# Compile instance
graph = create_graph()


async def run_agent(
    message: str,
    user_id: str,
    conversation_id: str | None = None,
    state_update_callback: Optional[Callable] = None,
) -> dict:
    """Run the LangGraph reasoning loop for a user message and return the execution results."""
    resolved_conv_id = conversation_id or str(uuid.uuid4())
    initial = AgentState(
        user_message=message,
        user_id=user_id,
        conversation_id=resolved_conv_id,
        state_update_callback=state_update_callback,
    )
    final_state = await graph.ainvoke(initial)
    return {
        "response": final_state.get("final_answer", ""),
        "conversation_id": final_state.get("conversation_id", resolved_conv_id),
        "prediction": final_state.get("prediction"),
        "citations": final_state.get("citations", []),
        "web_search_results": final_state.get("web_search_results", []),
    }