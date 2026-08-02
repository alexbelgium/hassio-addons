#!/lsiopy/bin/python3
"""Lazy TCP gate for the Headroom HTTP proxy.

The gate remains resident on the public Headroom port while the heavy Headroom
proxy (and its optional ONNX Kompress model) is started only for real traffic.
After an idle period the backend process is terminated, releasing its Python,
ONNX and model allocations. The next connection starts a fresh backend.

Only the Python standard library is imported here deliberately: the idle path
must not import Headroom, ONNX Runtime, transformers or the MCP SDK.
"""

from __future__ import annotations

import asyncio
import contextlib
import json
import os
import signal
import socket
import sys
import time
from pathlib import Path
from typing import BinaryIO


def _int_env(name: str, default: int, minimum: int = 1) -> int:
    try:
        value = int(os.environ.get(name, str(default)))
    except (TypeError, ValueError):
        value = default
    return max(minimum, value)


GATE_HOST = os.environ.get("HEADROOM_GATE_HOST", "127.0.0.1")
GATE_PORT = _int_env("HEADROOM_GATE_PORT", 8787)
BACKEND_HOST = os.environ.get("HEADROOM_BACKEND_HOST", "127.0.0.1")
BACKEND_PORT = _int_env("HEADROOM_BACKEND_PORT", 8789)
HEADROOM_BIN = os.environ.get("HEADROOM_REAL_BIN", "/usr/bin/headroom")
IDLE_TIMEOUT = _int_env("HEADROOM_IDLE_TIMEOUT_SECONDS", 900)
START_TIMEOUT = _int_env("HEADROOM_START_TIMEOUT_SECONDS", 60)
STOP_TIMEOUT = _int_env("HEADROOM_STOP_TIMEOUT_SECONDS", 10)
LOG_PATH = Path(os.environ.get("HEADROOM_BACKEND_LOG", str(Path.home() / ".headroom/proxy.log")))
HF_HOME = os.environ.get("HF_HOME", str(Path.home() / ".headroom/hf"))
MAX_HEADER_BYTES = 128 * 1024
COPY_CHUNK = 64 * 1024


def log(message: str) -> None:
    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{stamp}] headroom-gate: {message}", file=sys.stderr, flush=True)


class BackendUnavailable(RuntimeError):
    pass


class ProxyGate:
    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._process: asyncio.subprocess.Process | None = None
        self._log_handle: BinaryIO | None = None
        self._last_activity = time.monotonic()
        self._active_connections = 0
        self._stopping = False
        self._watch_task: asyncio.Task[None] | None = None

    @property
    def state(self) -> str:
        process = self._process
        if process is None:
            return "dormant"
        if process.returncode is None:
            return "running"
        return "stopped"

    def touch(self) -> None:
        self._last_activity = time.monotonic()

    async def _backend_healthy(self) -> bool:
        for path in ("/livez", "/health"):
            try:
                reader, writer = await asyncio.wait_for(
                    asyncio.open_connection(BACKEND_HOST, BACKEND_PORT), timeout=1.0
                )
                request = (
                    f"GET {path} HTTP/1.1\r\n"
                    f"Host: {BACKEND_HOST}:{BACKEND_PORT}\r\n"
                    "Connection: close\r\n\r\n"
                ).encode()
                writer.write(request)
                await writer.drain()
                line = await asyncio.wait_for(reader.readline(), timeout=1.0)
                writer.close()
                with contextlib.suppress(Exception):
                    await writer.wait_closed()
                if line.startswith(b"HTTP/") and b" 2" in line[:16]:
                    return True
            except (OSError, asyncio.TimeoutError):
                continue
        return False

    async def ensure_backend(self) -> None:
        if await self._backend_healthy():
            self.touch()
            return

        async with self._lock:
            if await self._backend_healthy():
                self.touch()
                return

            process = self._process
            if process is not None and process.returncode is None:
                await self._wait_until_healthy()
                self.touch()
                return

            if not os.path.isfile(HEADROOM_BIN) or not os.access(HEADROOM_BIN, os.X_OK):
                raise BackendUnavailable(f"Headroom executable is unavailable: {HEADROOM_BIN}")

            LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
            Path(HF_HOME).mkdir(parents=True, exist_ok=True)
            self._close_log_handle()
            self._log_handle = open(LOG_PATH, "ab", buffering=0)

            environment = os.environ.copy()
            environment.update(
                {
                    "HF_HOME": HF_HOME,
                    "HEADROOM_PROXY_GATE": "1",
                }
            )
            command = [
                HEADROOM_BIN,
                "proxy",
                "--host",
                BACKEND_HOST,
                "--port",
                str(BACKEND_PORT),
                "--code-aware",
            ]
            log(f"starting backend on {BACKEND_HOST}:{BACKEND_PORT}")
            try:
                self._process = await asyncio.create_subprocess_exec(
                    *command,
                    env=environment,
                    stdout=self._log_handle,
                    stderr=asyncio.subprocess.STDOUT,
                    start_new_session=True,
                )
            except Exception as exc:
                self._process = None
                self._close_log_handle()
                raise BackendUnavailable(f"unable to start Headroom: {exc}") from exc

            self._watch_task = asyncio.create_task(self._watch_backend(self._process))
            try:
                await self._wait_until_healthy()
            except Exception:
                await self._terminate_backend_locked("startup failure")
                raise
            self.touch()

    async def _wait_until_healthy(self) -> None:
        deadline = time.monotonic() + START_TIMEOUT
        while time.monotonic() < deadline:
            process = self._process
            if process is not None and process.returncode is not None:
                raise BackendUnavailable(
                    f"Headroom exited during startup with status {process.returncode}; "
                    f"see {LOG_PATH}"
                )
            if await self._backend_healthy():
                log("backend is ready")
                return
            await asyncio.sleep(0.25)
        raise BackendUnavailable(f"Headroom did not become ready within {START_TIMEOUT}s; see {LOG_PATH}")

    async def _watch_backend(self, process: asyncio.subprocess.Process) -> None:
        returncode = await process.wait()
        async with self._lock:
            was_current = self._process is process
            if was_current:
                self._process = None
                self._close_log_handle()
        if not self._stopping and was_current:
            log(f"backend exited with status {returncode}")

    async def stop_backend(self, reason: str) -> None:
        async with self._lock:
            await self._terminate_backend_locked(reason)

    async def _terminate_backend_locked(self, reason: str) -> None:
        process = self._process
        if process is None:
            self._close_log_handle()
            return
        if process.returncode is not None:
            self._process = None
            self._close_log_handle()
            return

        log(f"stopping backend ({reason})")
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            await asyncio.wait_for(process.wait(), timeout=STOP_TIMEOUT)
        except asyncio.TimeoutError:
            log("backend did not stop after SIGTERM; sending SIGKILL")
            with contextlib.suppress(ProcessLookupError):
                os.killpg(process.pid, signal.SIGKILL)
            with contextlib.suppress(Exception):
                await process.wait()
        self._process = None
        self._close_log_handle()

    def _close_log_handle(self) -> None:
        if self._log_handle is not None:
            with contextlib.suppress(Exception):
                self._log_handle.close()
            self._log_handle = None

    async def idle_monitor(self) -> None:
        interval = max(5, min(30, IDLE_TIMEOUT // 4))
        while not self._stopping:
            await asyncio.sleep(interval)
            process = self._process
            idle_for = time.monotonic() - self._last_activity
            if (
                process is not None
                and process.returncode is None
                and idle_for >= IDLE_TIMEOUT
            ):
                await self.stop_backend(f"idle for {int(idle_for)}s")

    def status_payload(self) -> bytes:
        process = self._process
        payload = {
            "status": self.state,
            "backend_pid": process.pid if process is not None and process.returncode is None else None,
            "active_connections": self._active_connections,
            "idle_seconds": round(time.monotonic() - self._last_activity, 1),
            "idle_timeout_seconds": IDLE_TIMEOUT,
            "backend": f"{BACKEND_HOST}:{BACKEND_PORT}",
        }
        body = json.dumps(payload, separators=(",", ":")).encode()
        return (
            b"HTTP/1.1 200 OK\r\n"
            b"Content-Type: application/json\r\n"
            + f"Content-Length: {len(body)}\r\n".encode()
            + b"Connection: close\r\n\r\n"
            + body
        )

    async def handle_client(self, client_reader: asyncio.StreamReader, client_writer: asyncio.StreamWriter) -> None:
        self._active_connections += 1
        real_traffic = False
        peer = client_writer.get_extra_info("peername")
        try:
            try:
                initial = await asyncio.wait_for(client_reader.readuntil(b"\r\n\r\n"), timeout=15.0)
            except (asyncio.IncompleteReadError, asyncio.LimitOverrunError, asyncio.TimeoutError):
                return
            if len(initial) > MAX_HEADER_BYTES:
                await self._send_error(client_writer, 431, "request headers too large")
                return

            first_line = initial.split(b"\r\n", 1)[0]
            parts = first_line.split(b" ")
            target = parts[1].split(b"?", 1)[0] if len(parts) >= 2 else b""
            if target == b"/gate/status":
                client_writer.write(self.status_payload())
                await client_writer.drain()
                return

            real_traffic = True
            self.touch()
            try:
                await self.ensure_backend()
                backend_reader, backend_writer = await asyncio.wait_for(
                    asyncio.open_connection(BACKEND_HOST, BACKEND_PORT), timeout=5.0
                )
            except (BackendUnavailable, OSError, asyncio.TimeoutError) as exc:
                log(f"backend unavailable for {peer}: {exc}")
                await self._send_error(client_writer, 503, str(exc))
                return

            backend_writer.write(initial)
            await backend_writer.drain()
            self.touch()

            upstream = asyncio.create_task(self._pipe(client_reader, backend_writer))
            downstream = asyncio.create_task(self._pipe(backend_reader, client_writer))
            done, pending = await asyncio.wait(
                {upstream, downstream}, return_when=asyncio.FIRST_COMPLETED
            )
            for task in pending:
                task.cancel()
            for task in done | pending:
                with contextlib.suppress(asyncio.CancelledError, ConnectionError, OSError):
                    await task
            backend_writer.close()
            with contextlib.suppress(Exception):
                await backend_writer.wait_closed()
        finally:
            self._active_connections = max(0, self._active_connections - 1)
            if real_traffic:
                self.touch()
            client_writer.close()
            with contextlib.suppress(Exception):
                await client_writer.wait_closed()

    async def _pipe(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        while True:
            data = await reader.read(COPY_CHUNK)
            if not data:
                with contextlib.suppress(Exception):
                    writer.write_eof()
                return
            writer.write(data)
            await writer.drain()
            self.touch()

    @staticmethod
    async def _send_error(writer: asyncio.StreamWriter, status: int, detail: str) -> None:
        reason = "Service Unavailable" if status == 503 else "Request Header Fields Too Large"
        body = json.dumps({"error": detail}).encode()
        response = (
            f"HTTP/1.1 {status} {reason}\r\n"
            "Content-Type: application/json\r\n"
            f"Content-Length: {len(body)}\r\n"
            "Connection: close\r\n\r\n"
        ).encode() + body
        writer.write(response)
        with contextlib.suppress(Exception):
            await writer.drain()

    async def shutdown(self) -> None:
        self._stopping = True
        await self.stop_backend("gate shutdown")


async def async_main() -> None:
    gate = ProxyGate()
    loop = asyncio.get_running_loop()
    stop_event = asyncio.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        with contextlib.suppress(NotImplementedError):
            loop.add_signal_handler(sig, stop_event.set)

    server = await asyncio.start_server(
        gate.handle_client,
        GATE_HOST,
        GATE_PORT,
        limit=MAX_HEADER_BYTES + 1,
        family=socket.AF_INET,
    )
    addresses = ", ".join(str(sock.getsockname()) for sock in server.sockets or [])
    log(
        f"listening on {addresses}; backend is lazy and stops after {IDLE_TIMEOUT}s idle; "
        f"status endpoint: /gate/status"
    )
    monitor = asyncio.create_task(gate.idle_monitor())
    async with server:
        await stop_event.wait()
    monitor.cancel()
    with contextlib.suppress(asyncio.CancelledError):
        await monitor
    await gate.shutdown()


if __name__ == "__main__":
    try:
        asyncio.run(async_main())
    except KeyboardInterrupt:
        pass
