import logging
from typing import Any, TypedDict

from langgraph.graph import END, StateGraph
from langgraph.types import Send

logger = logging.getLogger(__name__)


class AgentState(TypedDict):
    input: str
    conversation_id: str | None
    prediction: Any
    retrieved_docs: list[str]
    response: str


def create_graph() -> StateGraph:
    from app.agent.supervisor import route_to_workers
    from app.agent.predictive_node import predictive_node
    from app.agent.rag_node import rag_node
    from app.agent.response_node import response_node

    builder = StateGraph(AgentState)

    builder.add_node("predictive", predictive_node)
    builder.add_node("rag", rag_node)
    builder.add_node("response", response_node)

    builder.set_conditional_entry_point(
        route_to_workers,
        path_map=["predictive", "rag"],
    )

    builder.add_edge("predictive", "response")
    builder.add_edge("rag", "response")
    builder.add_edge("response", END)

    return builder.compile()


graph = create_graph()


async def run_agent(input_text: str, conversation_id: str | None = None) -> dict[str, Any]:
    initial_state: AgentState = {
        "input": input_text,
        "conversation_id": conversation_id,
        "prediction": None,
        "retrieved_docs": [],
        "response": "",
    }
    result = await graph.ainvoke(initial_state)
    return result
