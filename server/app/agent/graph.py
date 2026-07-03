import logging

from langgraph.graph import END, StateGraph

from app.agent.state import AgentState
from app.agent.supervisor import supervisor_node, route_after_supervisor, tools_node
from app.agent.response_node import response_node

logger = logging.getLogger(__name__)


def create_graph() -> StateGraph:
    builder = StateGraph(AgentState)

    builder.add_node("supervisor", supervisor_node)
    builder.add_node("tools", tools_node)
    builder.add_node("respond", response_node)

    builder.set_entry_point("supervisor")

    builder.add_conditional_edges("supervisor", route_after_supervisor, {
        "tools": "tools",
        "respond": "respond",
    })

    builder.add_edge("tools", "supervisor")
    builder.add_edge("respond", END)

    return builder.compile()


graph = create_graph()


async def run_agent(message: str, conversation_id: str | None = None) -> dict:
    initial = AgentState(
        user_message=message,
        conversation_id=conversation_id or "",
    )
    final_state = await graph.ainvoke(initial)
    return {
        "response": final_state.get("final_answer", ""),
        "conversation_id": final_state.get("conversation_id", conversation_id or ""),
    }
