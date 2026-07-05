import asyncio
import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import jwt as jose_jwt, JWTError

from app.core.config import settings
from app.schemas.events import EventSanitizer
from app.core.logging import log_agent_event
from app.agent.graph import run_agent

logger = logging.getLogger(__name__)

router = APIRouter(tags=["chat"])

_active_connections: dict[str, WebSocket] = {}
_connection_locks: dict[str, asyncio.Lock] = {}


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


async def _acquire_connection(user_id: str, websocket: WebSocket) -> None:
    if user_id not in _connection_locks:
        _connection_locks[user_id] = asyncio.Lock()
    
    async with _connection_locks[user_id]:
        if user_id in _active_connections:
            old_ws = _active_connections[user_id]
            try:
                await old_ws.close(code=4000, reason="New connection established")
            except Exception:
                pass
            _active_connections.pop(user_id, None)
            logger.info("Closed old WebSocket for user=%s", user_id)
        
        _active_connections[user_id] = websocket


async def _release_connection(user_id: str, websocket: WebSocket) -> None:
    if user_id not in _connection_locks:
        _connection_locks[user_id] = asyncio.Lock()
    
    async with _connection_locks[user_id]:
        if _active_connections.get(user_id) is websocket:
            _active_connections.pop(user_id, None)


@router.websocket("/ws/v1/chat")
async def chat_websocket(websocket: WebSocket):
    await websocket.accept()

    user_id = await _verify_ws_jwt(websocket)
    if user_id is None:
        return

    await _acquire_connection(user_id, websocket)
    logger.info("WS client connected: user=%s", user_id)

    is_closed = False
    current_agent_task: asyncio.Task | None = None

    async def safe_send(event: dict) -> bool:
        nonlocal is_closed
        if is_closed:
            return False
        try:
            if "timestamp" not in event or not event["timestamp"]:
                event["timestamp"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
            sanitized = EventSanitizer.sanitize(event)
            await websocket.send_text(json.dumps(sanitized))
            return True
        except Exception as e:
            logger.debug("Failed to send WebSocket message: %s", e)
            is_closed = True
            return False

    async def send_callback(event: dict) -> None:
        await safe_send(event)

    try:
        while True:
            try:
                raw = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=settings.WS_HEARTBEAT_TIMEOUT
                )
                data = json.loads(raw)

                if data.get("type") == "ping":
                    await safe_send({"type": "pong"})
                    log_agent_event("pong", user_id=user_id, duration_ms=0)
                    continue

                if data.get("type") == "user_message":
                    if not await _check_rate_limit(user_id, "msg_per_min", settings.WS_RATE_MSG_PER_MIN):
                        await safe_send({
                            "type": "error",
                            "message": "Batas pesan tercapai, coba lagi sebentar.",
                            "fatal": False,
                        })
                        continue

                    msg = data.get("message", "")
                    conv_id = data.get("conversation_id", "")

                    log_agent_event("user_message", user_id=user_id, conversation_id=conv_id)

                    if current_agent_task and not current_agent_task.done():
                        logger.warning("Cancelling previous agent task for user=%s", user_id)
                        current_agent_task.cancel()
                        try:
                            await current_agent_task
                        except asyncio.CancelledError:
                            pass

                    current_agent_task = asyncio.create_task(
                        _run_agent_safe(msg, user_id, conv_id, send_callback)
                    )

            except asyncio.TimeoutError:
                ping_sent = await safe_send({
                    "type": "ping",
                    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
                })
                if not ping_sent:
                    logger.info("Client not responding, closing connection: user=%s", user_id)
                    break
            except json.JSONDecodeError as e:
                logger.warning("Invalid JSON from %s: %s", user_id, e)
                await safe_send({
                    "type": "error",
                    "message": "Format pesan tidak valid",
                    "fatal": False,
                })

    except WebSocketDisconnect:
        logger.info("WS client disconnected: user=%s", user_id)
    except Exception as e:
        logger.exception("WS error: user=%s", user_id)
        await safe_send({
            "type": "error",
            "message": "Terjadi kesalahan internal.",
            "fatal": False,
        })
    finally:
        is_closed = True
        if current_agent_task and not current_agent_task.done():
            current_agent_task.cancel()
            try:
                await current_agent_task
            except asyncio.CancelledError:
                pass
        await _release_connection(user_id, websocket)
        try:
            await websocket.close()
        except Exception:
            pass
        logger.info("WebSocket connection closed for user=%s", user_id)


async def _run_agent_safe(msg: str, user_id: str, conv_id: str, callback) -> None:
    try:
        agent_res = await run_agent(
            message=msg,
            user_id=user_id,
            conversation_id=conv_id,
            state_update_callback=callback,
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

        await callback(final_event)

    except asyncio.CancelledError:
        logger.info("Agent task cancelled for user=%s", user_id)
        raise
    except Exception as e:
        logger.exception("Agent run failed for user %s", user_id)
        await callback({
            "type": "error",
            "node": "agent",
            "message": f"Terjadi kesalahan saat memproses permintaan Anda: {str(e)}",
            "fatal": False,
        })


@router.websocket("/ws/v1/health")
async def health_websocket(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            raw = await asyncio.wait_for(websocket.receive_text(), timeout=30)
            data = json.loads(raw)
            if data.get("type") == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
    except (WebSocketDisconnect, asyncio.TimeoutError):
        pass
    except Exception as e:
        logger.debug("Health WS error: %s", e)
    finally:
        try:
            await websocket.close()
        except Exception:
            pass