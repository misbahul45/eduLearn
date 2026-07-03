import logging

from app.agent.graph import AgentState
from app.rag.retriever import Retriever

logger = logging.getLogger(__name__)


async def rag_node(state: AgentState) -> dict:
    logger.info("RAG node processing: %s", state["input"][:50])

    retriever = Retriever()
    try:
        docs = await retriever.search(state["input"])
        return {"retrieved_docs": docs}
    except Exception as e:
        logger.exception("RAG retrieval failed")
        return {"retrieved_docs": []}
