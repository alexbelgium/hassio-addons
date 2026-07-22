#!/usr/bin/env python3
"""Migrate legacy vogler/free-games-claimer JSON history to the remaster DB."""

from __future__ import annotations

import json
import os
import shutil
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

DATA_DIR = Path(os.environ.get("FGC_DATA_DIR", "/data"))
LEGACY_DIR = DATA_DIR / "data"
DATABASE = DATA_DIR / "fgc.db"
MARKER = DATA_DIR / ".vogler-remaster-migrated-v1.json"
BACKUP = DATA_DIR / "fgc.db.pre-vogler-migration"

SOURCES = {
    "epic": "epic-games.json",
    "prime": "prime-gaming.json",
    "gog": "gog.json",
}


def log(message: str) -> None:
    print(f"[legacy migration] {message}", flush=True)


def locate_source(filename: str) -> Path | None:
    """Prefer the old nested data directory, with a root fallback."""
    for candidate in (LEGACY_DIR / filename, DATA_DIR / filename):
        if candidate.is_file():
            return candidate
    return None


def normalize_timestamp(value: Any) -> str:
    if isinstance(value, str) and value.strip():
        raw = value.strip().replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(raw)
            if parsed.tzinfo is not None:
                parsed = parsed.astimezone(timezone.utc).replace(tzinfo=None)
            return parsed.isoformat(sep=" ", timespec="seconds")
        except ValueError:
            pass
    return datetime.now(timezone.utc).replace(tzinfo=None).isoformat(
        sep=" ", timespec="seconds"
    )


def clean(value: Any, *, default: str = "", limit: int | None = None) -> str:
    result = default if value is None else str(value)
    if limit is not None:
        result = result[:limit]
    return result


def iter_records(store: str, payload: Any, source: Path) -> Iterator[dict[str, Any]]:
    if not isinstance(payload, dict):
        raise ValueError(f"{source} does not contain a JSON object")

    for user, games in payload.items():
        if not isinstance(games, dict):
            continue

        for legacy_id, value in games.items():
            record = value if isinstance(value, dict) else {}
            title = clean(record.get("title"), default=clean(legacy_id), limit=512)
            game_id = clean(legacy_id, default=title, limit=256)
            if not game_id:
                game_id = title[:256] or "unknown"

            legacy_store = record.get("store")
            extra = {
                "migration_source": str(source),
                "legacy_store": legacy_store,
                "legacy_time": record.get("time") or record.get("timestamp"),
            }
            extra = {key: val for key, val in extra.items() if val not in (None, "")}

            yield {
                "store": store,
                "user": clean(user, default="unknown", limit=128) or "unknown",
                "game_id": game_id,
                "title": title or game_id,
                "url": clean(record.get("url"), limit=None) or None,
                "status": clean(record.get("status"), default="unknown", limit=64)
                or "unknown",
                "code": clean(record.get("code"), limit=128) or None,
                "extra": json.dumps(extra, ensure_ascii=False) if extra else None,
                "created_at": normalize_timestamp(
                    record.get("time") or record.get("timestamp")
                ),
            }


def ensure_schema(connection: sqlite3.Connection) -> None:
    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS claimed_games (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            store VARCHAR(32) NOT NULL,
            user VARCHAR(128) NOT NULL,
            game_id VARCHAR(256) NOT NULL,
            title VARCHAR(512) NOT NULL,
            url TEXT,
            status VARCHAR(64) NOT NULL DEFAULT 'unknown',
            code VARCHAR(128),
            extra TEXT,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS ix_claimed_games_store ON claimed_games (store);
        CREATE INDEX IF NOT EXISTS ix_claimed_games_user ON claimed_games (user);
        CREATE INDEX IF NOT EXISTS ix_claimed_games_game_id ON claimed_games (game_id);
        """
    )


def migrate() -> int:
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    if MARKER.exists():
        log("Legacy claim history was already migrated")
        return 0

    sources = {
        store: source
        for store, filename in SOURCES.items()
        if (source := locate_source(filename)) is not None
    }
    legacy_browser = LEGACY_DIR / "browser"

    if not sources:
        if legacy_browser.exists():
            log(
                "Legacy Firefox browser data was found but cannot be converted to "
                "the remaster Chromium profile; a one-time login may be required"
            )
        MARKER.write_text(
            json.dumps(
                {
                    "migrated_at": datetime.now(timezone.utc).isoformat(),
                    "imported": 0,
                    "sources": [],
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        log("No legacy claim-history files were found")
        return 0

    if DATABASE.exists() and not BACKUP.exists():
        shutil.copy2(DATABASE, BACKUP)
        log(f"Backed up the existing database to {BACKUP}")

    imported = 0
    skipped = 0
    errors: list[str] = []

    try:
        with sqlite3.connect(DATABASE) as connection:
            ensure_schema(connection)

            for store, source in sources.items():
                try:
                    payload = json.loads(source.read_text(encoding="utf-8"))
                    source_imported = 0
                    for record in iter_records(store, payload, source):
                        exists = connection.execute(
                            """
                            SELECT 1 FROM claimed_games
                            WHERE store = ? AND user = ? AND game_id = ?
                            LIMIT 1
                            """,
                            (record["store"], record["user"], record["game_id"]),
                        ).fetchone()
                        if exists:
                            skipped += 1
                            continue

                        connection.execute(
                            """
                            INSERT INTO claimed_games (
                                store, user, game_id, title, url, status, code,
                                extra, created_at, updated_at
                            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            """,
                            (
                                record["store"],
                                record["user"],
                                record["game_id"],
                                record["title"],
                                record["url"],
                                record["status"],
                                record["code"],
                                record["extra"],
                                record["created_at"],
                                record["created_at"],
                            ),
                        )
                        imported += 1
                        source_imported += 1

                    connection.commit()
                    log(f"Imported {source_imported} record(s) from {source}")
                except (OSError, ValueError, json.JSONDecodeError, sqlite3.Error) as err:
                    connection.rollback()
                    message = f"Failed to import {source}: {err}"
                    errors.append(message)
                    log(message)
    except sqlite3.Error as err:
        log(f"Database migration failed: {err}")
        return 1

    if legacy_browser.exists():
        log(
            "Legacy Firefox browser data remains in /data/data/browser. It is "
            "not compatible with Chromium, so use noVNC for a one-time login if needed."
        )

    if errors:
        log("Migration was incomplete and will be retried on the next start")
        return 0

    MARKER.write_text(
        json.dumps(
            {
                "migrated_at": datetime.now(timezone.utc).isoformat(),
                "imported": imported,
                "skipped_existing": skipped,
                "sources": [str(path) for path in sources.values()],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    log(f"Migration complete: {imported} imported, {skipped} already present")
    return 0


if __name__ == "__main__":
    sys.exit(migrate())
