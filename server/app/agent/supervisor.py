import logging

from langgraph.types import Send

from app.agent.graph import AgentState

logger = logging.getLogger(__name__)


def route_to_workers(state: AgentState) -> list[Send]:
    logger.info("Supervisor routing input: %s", state["input"][:50])
    return [
        Send("predictive", state),
        Send("rag", state),
    ]
