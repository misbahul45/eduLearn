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


import uuid
from typing import Callable, Optional

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

