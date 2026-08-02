#!/lsiopy/bin/python3
"""Run Headroom MCP with compression delegated to the single proxy backend.

Upstream Headroom MCP normally performs ``headroom_compress`` in its own
process. That imports the compression pipeline and can load a second copy of the
Kompress ONNX model in addition to the HTTP proxy. This adapter preserves the
upstream MCP protocol and retrieve/stats implementations, but replaces only its
local compression method with a call to the proxy's loopback-only
``/v1/compress`` endpoint.

The proxy gate starts the heavy backend on this first request and later unloads
it after the configured idle timeout. The MCP process therefore remains a
lightweight protocol bridge and never imports ``headroom.compress``.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
from types import MethodType
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Headroom MCP single-runtime adapter")
    parser.add_argument(
        "--proxy-url",
        default=os.environ.get("HEADROOM_PROXY_URL", "http://127.0.0.1:8787"),
    )
    parser.add_argument("--transport", default="stdio")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8788)
    parser.add_argument("--path", default="/mcp")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--direct", action="store_true")
    args, unknown = parser.parse_known_args()
    if unknown:
        print(f"headroom-mcp-proxy: ignoring unsupported arguments: {unknown}", file=sys.stderr)
    if args.transport.lower() != "stdio":
        parser.error("only stdio transport is supported by the add-on adapter")
    return args


def _number(data: dict[str, Any], key: str) -> int:
    value = data.get(key, 0)
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def make_proxy_compressor(proxy_url: str):
    endpoint = f"{proxy_url.rstrip('/')}/v1/compress"
    model = os.environ.get("HEADROOM_MCP_MODEL", "claude-sonnet-4-5-20250929")

    def compress_via_proxy(_self, content: str) -> dict[str, Any]:
        # Imported here, not at module import, so MCP startup stays small. httpx is
        # already a dependency of Headroom's MCP server for retrieve/stats.
        import httpx

        response = httpx.post(
            endpoint,
            json={
                "messages": [{"role": "tool", "content": content}],
                "model": model,
            },
            timeout=httpx.Timeout(180.0, connect=75.0),
        )
        response.raise_for_status()
        data = response.json()
        if not isinstance(data, dict):
            raise RuntimeError("Headroom proxy returned a non-object compression response")

        messages = data.get("messages")
        compressed: Any = content
        if isinstance(messages, list) and messages:
            last = messages[-1]
            if isinstance(last, dict) and "content" in last:
                compressed = last["content"]
        if not isinstance(compressed, str):
            compressed = json.dumps(compressed, ensure_ascii=False)

        hashes = data.get("ccr_hashes")
        hash_key = next((item for item in hashes if isinstance(item, str)), None) if isinstance(hashes, list) else None
        before = _number(data, "tokens_before")
        after = _number(data, "tokens_after")
        saved = _number(data, "tokens_saved")
        if saved <= 0:
            saved = max(0, before - after)
        savings_percent = round(saved / before * 100, 1) if before > 0 else 0.0
        transforms = data.get("transforms_applied")
        if not isinstance(transforms, list):
            transforms = []

        note = "Compression was executed by the shared Headroom proxy runtime."
        if hash_key:
            note += (
                f" Original stored with hash={hash_key}. "
                "Use mcp__headroom__headroom_retrieve to recover it."
            )
        return {
            "compressed": compressed,
            "hash": hash_key,
            "original_tokens": before,
            "compressed_tokens": after,
            "tokens_saved": saved,
            "savings_percent": savings_percent,
            "transforms": transforms,
            "note": note,
        }

    return compress_via_proxy


async def run() -> None:
    args = parse_args()

    # Defense in depth. The adapter never calls the local compressor, but keep
    # the MCP process explicitly unable to initialize Kompress if upstream code
    # changes or an unrelated import probes the compression pipeline.
    os.environ.pop("HF_HOME", None)
    os.environ["HEADROOM_DISABLE_KOMPRESS"] = "1"
    os.environ["HEADROOM_PROXY_URL"] = args.proxy_url

    from headroom.ccr.mcp_server import HeadroomMCPServer

    server = HeadroomMCPServer(proxy_url=args.proxy_url, check_proxy=True)
    server._compress_content = MethodType(make_proxy_compressor(args.proxy_url), server)
    try:
        await server.run_stdio()
    finally:
        await server.cleanup()


if __name__ == "__main__":
    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        pass
