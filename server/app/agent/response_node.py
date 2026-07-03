import logging

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

from app.agent.graph import AgentState
from app.core.config import settings

logger = logging.getLogger(__name__)


async def response_node(state: AgentState) -> dict:
    logger.info("Response node generating final answer")

    llm = ChatOpenAI(
        api_key=settings.FLAZ_API_KEY,
        base_url=settings.FLAZ_BASE_URL,
        model=settings.LLM_MODEL,
    )

    system_prompt = (
        "You are an AI tutor for an educational platform. "
        "Answer the user's question based on the retrieved knowledge and any ML predictions. "
        "Be concise, accurate, and educational."
    )

    context_parts = []
    if state.get("retrieved_docs"):
        context_parts.append(
            "Retrieved knowledge:\n" + "\n".join(state["retrieved_docs"])
        )
    if state.get("prediction") is not None:
        context_parts.append(f"ML Prediction: {state['prediction']}")

    context = "\n\n".join(context_parts) if context_parts else "No additional context available."

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Context:\n{context}\n\nUser question: {state['input']}"),
    ]

    try:
        response = await llm.ainvoke(messages)
        return {"response": response.content}
    except Exception as e:
        logger.exception("LLM response failed")
        return {"response": "I'm sorry, I couldn't generate a response at this time."}
