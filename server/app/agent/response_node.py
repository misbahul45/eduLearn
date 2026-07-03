import logging

from langchain_core.messages import SystemMessage, HumanMessage

from app.agent.state import AgentState
from app.llm import get_llm

logger = logging.getLogger(__name__)

RESPONSE_PROMPT = (
    "Kamu adalah EduLearn AI virtual tutor. "
    "Susun jawaban dalam Bahasa Indonesia. "
    "Gunakan konteks dari knowledge base (citations) dan hasil web search. "
    "Jika ada prediksi kelulusan, cantumkan di jawaban. "
    "Jawaban harus informatif, edukatif, dan akurat."
)


async def response_node(state: AgentState) -> dict:
    logger.info("Response node generating final answer")

    context_parts = [f"User question: {state.user_message}"]
    if state.citations:
        context_parts.append("Citations:")
        for i, c in enumerate(state.citations):
            ctx = state.citations[i]
            doc = ctx.get("document") if isinstance(ctx, dict) else ""
            snippet = ctx.get("snippet", str(ctx)[:200]) if isinstance(ctx, dict) else str(ctx)[:200]
            context_parts.append(f"  [{i+1}] {doc}: {snippet}")
    if state.prediction:
        prob = 0.0
        label = ""
        if isinstance(state.prediction, dict):
            prob = state.prediction.get("probability", 0.0)
            label = state.prediction.get("label", "")
        elif hasattr(state.prediction, "probability"):
            prob = state.prediction.probability
            label = state.prediction.label
        context_parts.append(f"ML Prediction: {label} (probability: {prob})")
    if state.web_search_results:
        context_parts.append("Web search:")
        for i, w in enumerate(state.web_search_results):
            title = w.get("title", w.get("url", "")) if isinstance(w, dict) else ""
            url = w.get("url", "") if isinstance(w, dict) else ""
            snippet = w.get("snippet", "") if isinstance(w, dict) else ""
            context_parts.append(f"  [{i+1}] {title}: {url}")

    context = "\n".join(context_parts)

    llm = get_llm()
    messages = [
        SystemMessage(content=RESPONSE_PROMPT),
        HumanMessage(content=f"Context:\n{context}"),
    ]

    try:
        response = await llm.ainvoke(messages)
        return {"final_answer": response.content}
    except Exception as e:
        logger.exception("LLM response failed")
        return {"final_answer": "Maaf, saya tidak dapat menyusun jawaban saat ini."}
