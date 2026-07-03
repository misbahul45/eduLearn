import json
import logging
import sys
from datetime import datetime, timezone


class _JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        obj = {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        extra = getattr(record, "extra_fields", {})
        obj.update(extra)
        if record.exc_info and record.exc_info[0]:
            obj["exception"] = self.formatException(record.exc_info)
        return json.dumps(obj, ensure_ascii=False, default=str)


def setup_logging() -> None:
    console_formatter = logging.Formatter(
        "[%(asctime)s] %(levelname)s | %(name)s | %(filename)s:%(lineno)d | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(console_formatter)

    root = logging.getLogger()
    root.setLevel(logging.INFO)
    root.addHandler(handler)

    agent_logger = logging.getLogger("agent.trace")
    agent_logger.setLevel(logging.INFO)
    agent_logger.propagate = False

    json_handler = logging.StreamHandler(sys.stdout)
    json_handler.setFormatter(_JsonFormatter())
    agent_logger.addHandler(json_handler)


def log_agent_event(event_type: str, **fields: object) -> None:
    logger = logging.getLogger("agent.trace")
    logger.info(event_type, extra={"extra_fields": fields})
