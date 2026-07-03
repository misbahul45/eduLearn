import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.config import settings
from app.schemas.events import (
    FinalEvent,
    StateUpdate,
    TokenEvent,
    UserMessage,
    WSEvent,
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["chat"])


@router.websocket("/ws/v1/chat")
async def chat_websocket(websocket: WebSocket):
    await websocket.accept()

    logger.info("WebSocket client connected")

    try:
        async with websocket:
            while True:
                raw = await websocket.receive_text()
                data = json.loads(raw)

                if data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                    continue

                if data.get("type") == "user_message":
                    msg = data.get("message", "")
                    conv_id = data.get("conversation_id")

                    await websocket.send_text(
                        StateUpdate(state="supervisor", message="Menganalisis pertanyaan...").model_dump_json()
                    )

                    await websocket.send_text(
                        TokenEvent(token="Ini adalah jawaban sementara. ").model_dump_json()
                    )

                    await websocket.send_text(
                        FinalEvent(
                            message="Endpoint WebSocket masih dalam pengembangan. Gunakan REST fallback.",
                            conversation_id=conv_id or "",
                        ).model_dump_json()
                    )

    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected")
    except Exception as e:
        logger.exception("WebSocket error")
        try:
            await websocket.send_text(
                json.dumps({"type": "error", "code": "internal_error", "message": "Terjadi kesalahan internal"})
            )
        except Exception:
            pass


@router.websocket("/ws/v1/health")
async def health_websocket(websocket: WebSocket):
    await websocket.accept()
    try:
        async with websocket:
            while True:
                raw = await websocket.receive_text()
                data = json.loads(raw)
                if data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
    except WebSocketDisconnect:
        pass
