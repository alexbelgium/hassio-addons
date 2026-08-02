#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Keep every existing Headroom CLI command unchanged, but intercept the MCP
# server entrypoint so it uses the add-on's single-runtime adapter. The real
# binary is intentionally outside /usr/local/bin; writing the wrapper there
# makes it the command 82-claude_tools.sh registers in Claude Desktop/Code.
REAL_HEADROOM=""
for candidate in /usr/bin/headroom /lsiopy/bin/headroom; do
    if [ -x "$candidate" ]; then
        REAL_HEADROOM="$candidate"
        break
    fi
done

if [ -z "$REAL_HEADROOM" ]; then
    bashio::log.warning "Headroom executable was not found; MCP adapter wrapper was not installed"
    exit 0
fi

# The adapter intentionally uses a small, stable subset of the upstream MCP
# server. Since Headroom is installed unpinned at image build time, verify that
# subset before replacing the command. A future incompatible Headroom release
# therefore keeps its native MCP server instead of breaking Claude startup.
if ! /lsiopy/bin/python3 - <<'PY'
from headroom.ccr.mcp_server import HeadroomMCPServer

for name in ("run_stdio", "cleanup", "_compress_content"):
    if not callable(getattr(HeadroomMCPServer, name, None)):
        raise SystemExit(f"HeadroomMCPServer.{name} is unavailable")
PY
then
    bashio::log.warning "Installed Headroom is incompatible with the single-runtime MCP adapter; preserving the native MCP server"
    exit 0
fi

wrapper="$(mktemp /usr/local/bin/.headroom-wrapper.XXXXXX)"
cleanup() {
    rm -f "$wrapper"
}
trap cleanup EXIT

cat > "$wrapper" <<EOF
#!/bin/sh
REAL_HEADROOM="$REAL_HEADROOM"
if [ "\${1:-}" = "mcp" ] && [ "\${2:-}" = "serve" ]; then
    shift 2
    unset HF_HOME
    export HEADROOM_DISABLE_KOMPRESS=1
    exec /lsiopy/bin/python3 /usr/local/bin/headroom-mcp-proxy.py "\$@"
fi
exec "\$REAL_HEADROOM" "\$@"
EOF
chmod 0755 "$wrapper"
mv -f "$wrapper" /usr/local/bin/headroom
trap - EXIT

bashio::log.info "Headroom MCP compression is delegated to the shared lazy proxy runtime"
