from langchain_openai import ChatOpenAI

from app.core.config import settings


def get_llm() -> ChatOpenAI:
    return ChatOpenAI(
        api_key=settings.FLAZ_API_KEY,
        base_url=settings.FLAZ_BASE_URL,
        model=settings.LLM_MODEL,
        temperature=0.3,
    )
