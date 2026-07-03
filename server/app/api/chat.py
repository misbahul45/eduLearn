import logging

from fastapi import APIRouter, HTTPException

from app.agent.graph import run_agent
from app.schemas.chat import ChatRequest, ChatResponse

logger = logging.getLogger(__name__)

router = APIRouter(tags=["chat"])


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Message must not be empty")

    logger.info("Chat request received: conversation=%s message=%s",
                request.conversation_id, request.message[:50])

    try:
        result = await run_agent(request.message, request.conversation_id)
        return ChatResponse(
            message=result["response"],
            conversation_id=result.get("conversation_id"),
        )
    except Exception as e:
        logger.exception("Chat processing failed")
        raise HTTPException(status_code=500, detail="Internal processing error")
