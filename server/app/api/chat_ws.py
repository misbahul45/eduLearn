import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, WebSocketException, status
from jose import jwt as jose_jwt, JWTError

from app.core.config import settings
from app.schemas.events import EventSanitizer
from app.core.logging import log_agent_event
from app.agent.graph import run_agent

logger = logging.getLogger(__name__)

router = APIRouter(tags=["chat"])

_active_connections: dict[str, int] = {}


async def _verify_ws_jwt(websocket: WebSocket) -> str | None:
    if not settings.WS_AUTH_REQUIRED:
        logger.warning("WS_AUTH_REQUIRED=false — authentication bypassed")
        return "dev_user"

    token: str | None = None

    subprotocols = websocket.headers.get("sec-websocket-protocol", "")
    for sp in subprotocols.split(","):
        sp = sp.strip()
        if sp.startswith("bearer."):
            token = sp.split("bearer.", 1)[1]
            break

    if not token:
        token = websocket.query_params.get("token")
        if token:
            logger.warning("WS auth via query param — prefer subprotocol next time")

    if not token:
        await websocket.close(code=4401, reason="Token tidak ditemukan")
        return None

    try:
        payload = jose_jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
        )
        user_id = payload.get("sub")
        if not user_id:
            raise JWTError("Missing sub")
        return str(user_id)
    except JWTError as e:
        logger.warning("WS JWT invalid: %s", e)
        await websocket.send_json({
            "type": "error",
            "message": "Token tidak valid atau kadaluarsa",
            "fatal": True,
        })
        await websocket.close(code=4401)
        return None


async def _check_rate_limit(user_id: str, metric: str, max_val: int, window: int = 60) -> bool:
    try:
        import redis.asyncio as aioredis
        r = aioredis.from_url(settings.REDIS_URL, socket_connect_timeout=2)
        key = f"ws:rate:{user_id}:{metric}"
        current = await r.incr(key)
        if current == 1:
            await r.expire(key, window)
        await r.aclose()
        return current <= max_val
    except Exception:
        return True


async def _track_connection(user_id: str, delta: int) -> bool:
    current = _active_connections.get(user_id, 0) + delta
    if delta > 0 and current > settings.WS_CONNECTION_LIMIT_PER_USER:
        return False
    if current <= 0:
        _active_connections.pop(user_id, None)
    else:
        _active_connections[user_id] = current
    return True


@router.websocket("/ws/v1/chat")
async def chat_websocket(websocket: WebSocket):
    await websocket.accept()

    user_id = await _verify_ws_jwt(websocket)
    if user_id is None:
        return

    if not await _track_connection(user_id, 1):
        await websocket.send_json({
            "type": "error",
            "message": "Terlalu banyak koneksi aktif. Tutup koneksi lain dan coba lagi.",
            "fatal": True,
        })
        await websocket.close(code=4401)
        return

    logger.info("WS client connected: user=%s", user_id)

    try:
        async with websocket:
            while True:
                raw = await websocket.receive_text()
                data = json.loads(raw)

                if data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                    log_agent_event("pong", user_id=user_id, duration_ms=0)
                    continue

                if data.get("type") == "user_message":
                    if not await _check_rate_limit(user_id, "msg_per_min", settings.WS_RATE_MSG_PER_MIN):
                        await websocket.send_json({
                            "type": "error",
                            "message": "Batas pesan tercapai, coba lagi sebentar.",
                            "fatal": False,
                        })
                        continue

                    msg = data.get("message", "")
                    conv_id = data.get("conversation_id", "")

                    log_agent_event("user_message", user_id=user_id, conversation_id=conv_id)

                    async def send_callback(event: dict) -> None:
                        if "timestamp" not in event or not event["timestamp"]:
                            event["timestamp"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
                        sanitized = EventSanitizer.sanitize(event)
                        await websocket.send_text(json.dumps(sanitized))

                    try:
                        agent_res = await run_agent(
                            message=msg,
                            user_id=user_id,
                            conversation_id=conv_id,
                            state_update_callback=send_callback,
                        )

                        citations_ids = [
                            c.source_id if hasattr(c, "source_id") else c.get("source_id", "")
                            for c in agent_res.get("citations", [])
                        ]
                        web_ids = [
                            w.result_id if hasattr(w, "result_id") else w.get("result_id", "")
                            for w in agent_res.get("web_search_results", [])
                        ]

                        pred = agent_res.get("prediction")
                        prediction_present = pred is not None
                        prediction_label = ""
                        if prediction_present:
                            prediction_label = pred.predicted_label if hasattr(pred, "predicted_label") else pred.get("predicted_label", "")

                        final_event = {
                            "type": "final",
                            "message": agent_res.get("response", ""),
                            "conversation_id": agent_res.get("conversation_id", ""),
                            "citations": citations_ids,
                            "web_results": web_ids,
                            "prediction_present": prediction_present,
                            "prediction_label": prediction_label,
                        }

                        await send_callback(final_event)

                    except Exception as e:
                        logger.exception("Agent run failed for user %s", user_id)
                        await send_callback({
                            "type": "error",
                            "message": f"Terjadi kesalahan saat memproses permintaan Anda: {str(e)}",
                            "fatal": False,
                        })

    except WebSocketDisconnect:
        logger.info("WS client disconnected: user=%s", user_id)
    except Exception as e:
        logger.exception("WS error: user=%s", user_id)
        try:
            await websocket.send_json({
                "type": "error",
                "message": "Terjadi kesalahan internal.",
                "fatal": False,
            })
        except Exception:
            pass
    finally:
        await _track_connection(user_id, -1)


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
