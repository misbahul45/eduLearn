"""
Migration: create all tables in PostgreSQL.

Usage:
    python -m app.db.migrations.run
"""
import asyncio
import logging

from app.db import Base, engine
from app.db.models import *  # noqa: F401, F403 — ensure all models are registered

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("migration")


async def migrate() -> None:
    logger.info("Starting database migration...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Migration complete — all tables created.")


async def drop_all() -> None:
    logger.warning("Dropping all tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    logger.warning("All tables dropped.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--drop", action="store_true", help="Drop all tables before create")
    args = parser.parse_args()

    if args.drop:
        asyncio.run(drop_all())
    asyncio.run(migrate())
