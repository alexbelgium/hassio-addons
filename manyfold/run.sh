#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -Eeuo pipefail

CONFIG_DIR="/config"
OPTIONS_JSON="/data/options.json"
SECRET_FILE="${CONFIG_DIR}/secret_key_base"
DEFAULT_LIBRARY_PATH="/share/manyfold/models"
DEFAULT_THUMBNAILS_PATH="/config/thumbnails"
DEFAULT_LOG_LEVEL="info"
DEFAULT_WEB_CONCURRENCY="4"
DEFAULT_RAILS_MAX_THREADS="16"
DEFAULT_DEFAULT_WORKER_CONCURRENCY="4"
DEFAULT_PERFORMANCE_WORKER_CONCURRENCY="1"
DEFAULT_MAX_FILE_UPLOAD_SIZE="1073741824"
DEFAULT_MAX_FILE_EXTRACT_SIZE="1073741824"

log() {
  echo "[manyfold-addon] $*"
}

die() {
  echo "[manyfold-addon] ERROR: $*" >&2
  exit 1
}

read_opt() {
  local key="$1"
  jq -er --arg k "$key" '.[$k]' "$OPTIONS_JSON" 2>/dev/null || true
}

normalize_path() {
  local raw="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$raw"
    return
  fi

  case "$raw" in
    /*) printf '%s\n' "$raw" ;;
    *) printf '/%s\n' "$raw" ;;
  esac
}

is_allowed_path() {
  local resolved="$1"
  case "$resolved" in
    /share|/share/*|/media|/media/*|/config|/config/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_mapped_path() {
  local label="$1"
  local raw="$2"
  local resolved

  resolved="$(normalize_path "$raw")"
  if ! is_allowed_path "$resolved"; then
    die "${label} '${raw}' resolves to '${resolved}', which is outside /share, /media, and /config"
  fi

  printf '%s\n' "$resolved"
}

ensure_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

ensure_existing_or_create() {
  local label="$1"
  local dir="$2"

  if [[ -d "$dir" ]]; then
    return
  fi

  if mkdir -p "$dir" 2>/dev/null; then
    return
  fi

  die "${label} '${dir}' does not exist and could not be created. Create it on the host or choose a writable path under /config."
}

chown_recursive_if_writable() {
  local owner="$1"
  local path="$2"

  if [[ ! -e "$path" ]]; then
    log "Skipping ownership update for ${path} (missing path)"
    return
  fi

  if [[ -w "$path" ]]; then
    chown -R "$owner" "$path"
    return
  fi

  log "Skipping ownership update for ${path} (read-only mapping)"
}

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 64
    return
  fi

  head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n'
}

start_manyfold() {
  if [[ -x /usr/src/app/bin/docker-entrypoint.sh ]]; then
    log "Starting Manyfold via /usr/src/app/bin/docker-entrypoint.sh foreman start"
    cd /usr/src/app
    exec ./bin/docker-entrypoint.sh foreman start
  fi

  if [[ -x /app/bin/docker-entrypoint.sh ]]; then
    log "Starting Manyfold via /app/bin/docker-entrypoint.sh foreman start"
    cd /app
    exec ./bin/docker-entrypoint.sh foreman start
  fi

  local candidate
  for candidate in \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/docker-entrypoint \
    /docker-entrypoint.sh \
    /entrypoint.sh
  do
    if [[ -x "$candidate" ]]; then
      log "Starting Manyfold via ${candidate}"
      if [[ "$candidate" == *docker-entrypoint* ]]; then
        exec "$candidate" foreman start
      fi
      exec "$candidate"
    fi
  done

  if command -v docker-entrypoint >/dev/null 2>&1; then
    log "Starting Manyfold via docker-entrypoint"
    exec docker-entrypoint foreman start
  fi

  if [[ -d /usr/src/app ]]; then
    cd /usr/src/app
  elif [[ -d /app ]]; then
    cd /app
  fi

  if command -v bundle >/dev/null 2>&1; then
    log "Starting Manyfold via rails server fallback"
    exec bundle exec rails server -b 0.0.0.0 -p 3214
  fi

  die "Could not find a known Manyfold entrypoint"
}

[[ -f "$OPTIONS_JSON" ]] || die "Missing options file at ${OPTIONS_JSON}"

PUID="$(read_opt puid)"; PUID="${PUID:-1000}"
PGID="$(read_opt pgid)"; PGID="${PGID:-1000}"
MULTIUSER="$(read_opt multiuser)"; MULTIUSER="${MULTIUSER:-true}"
LIBRARY_PATH_RAW="$(read_opt library_path)"; LIBRARY_PATH_RAW="${LIBRARY_PATH_RAW:-$DEFAULT_LIBRARY_PATH}"
THUMBNAILS_PATH_RAW="$(read_opt thumbnails_path)"; THUMBNAILS_PATH_RAW="${THUMBNAILS_PATH_RAW:-$DEFAULT_THUMBNAILS_PATH}"
LOG_LEVEL="$(read_opt log_level)"; LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
WEB_CONCURRENCY="$(read_opt web_concurrency)"; WEB_CONCURRENCY="${WEB_CONCURRENCY:-$DEFAULT_WEB_CONCURRENCY}"
RAILS_MAX_THREADS="$(read_opt rails_max_threads)"; RAILS_MAX_THREADS="${RAILS_MAX_THREADS:-$DEFAULT_RAILS_MAX_THREADS}"
DEFAULT_WORKER_CONCURRENCY="$(read_opt default_worker_concurrency)"; DEFAULT_WORKER_CONCURRENCY="${DEFAULT_WORKER_CONCURRENCY:-$DEFAULT_DEFAULT_WORKER_CONCURRENCY}"
PERFORMANCE_WORKER_CONCURRENCY="$(read_opt performance_worker_concurrency)"; PERFORMANCE_WORKER_CONCURRENCY="${PERFORMANCE_WORKER_CONCURRENCY:-$DEFAULT_PERFORMANCE_WORKER_CONCURRENCY}"
MAX_FILE_UPLOAD_SIZE="$(read_opt max_file_upload_size)"; MAX_FILE_UPLOAD_SIZE="${MAX_FILE_UPLOAD_SIZE:-$DEFAULT_MAX_FILE_UPLOAD_SIZE}"
MAX_FILE_EXTRACT_SIZE="$(read_opt max_file_extract_size)"; MAX_FILE_EXTRACT_SIZE="${MAX_FILE_EXTRACT_SIZE:-$DEFAULT_MAX_FILE_EXTRACT_SIZE}"
SECRET_KEY_BASE="$(read_opt secret_key_base)"; SECRET_KEY_BASE="${SECRET_KEY_BASE:-}"

[[ "$PUID" =~ ^[0-9]+$ ]] || die "puid must be a non-negative integer"
[[ "$PGID" =~ ^[0-9]+$ ]] || die "pgid must be a non-negative integer"
[[ "$WEB_CONCURRENCY" =~ ^[1-9][0-9]*$ ]] || die "web_concurrency must be a positive integer"
[[ "$RAILS_MAX_THREADS" =~ ^[1-9][0-9]*$ ]] || die "rails_max_threads must be a positive integer"
[[ "$DEFAULT_WORKER_CONCURRENCY" =~ ^[1-9][0-9]*$ ]] || die "default_worker_concurrency must be a positive integer"
[[ "$PERFORMANCE_WORKER_CONCURRENCY" =~ ^[1-9][0-9]*$ ]] || die "performance_worker_concurrency must be a positive integer"
[[ "$MAX_FILE_UPLOAD_SIZE" =~ ^[1-9][0-9]*$ ]] || die "max_file_upload_size must be a positive integer (bytes)"
[[ "$MAX_FILE_EXTRACT_SIZE" =~ ^[1-9][0-9]*$ ]] || die "max_file_extract_size must be a positive integer (bytes)"

LIBRARY_PATH="$(require_mapped_path "library_path" "$LIBRARY_PATH_RAW")"
THUMBNAILS_PATH="$(require_mapped_path "thumbnails_path" "$THUMBNAILS_PATH_RAW")"

case "$THUMBNAILS_PATH" in
  /config|/config/*) ;;
  *) die "thumbnails_path must resolve under /config for persistence" ;;
esac

ensure_dir "$CONFIG_DIR"
ensure_dir "$DEFAULT_THUMBNAILS_PATH"
ensure_existing_or_create "library_path" "$LIBRARY_PATH"
ensure_dir "$THUMBNAILS_PATH"
[[ -r "$LIBRARY_PATH" ]] || die "library_path '${LIBRARY_PATH}' is not readable"

if [[ -z "$SECRET_KEY_BASE" ]]; then
  if [[ -s "$SECRET_FILE" ]]; then
    SECRET_KEY_BASE="$(cat "$SECRET_FILE")"
    log "Loaded SECRET_KEY_BASE from ${SECRET_FILE}"
  else
    SECRET_KEY_BASE="$(generate_secret)"
    printf '%s' "$SECRET_KEY_BASE" > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    log "Generated and stored SECRET_KEY_BASE at ${SECRET_FILE}"
  fi
else
  printf '%s' "$SECRET_KEY_BASE" > "$SECRET_FILE"
  chmod 600 "$SECRET_FILE"
  log "Saved provided SECRET_KEY_BASE to ${SECRET_FILE}"
fi

export SECRET_KEY_BASE
export PUID
export PGID
export MULTIUSER
export MANYFOLD_MULTIUSER="$MULTIUSER"
export MANYFOLD_LIBRARY_PATH="$LIBRARY_PATH"
export MANYFOLD_THUMBNAILS_PATH="$THUMBNAILS_PATH"
export RAILS_LOG_LEVEL="$LOG_LEVEL"
export MANYFOLD_LOG_LEVEL="$LOG_LEVEL"
export WEB_CONCURRENCY
export RAILS_MAX_THREADS
export DEFAULT_WORKER_CONCURRENCY
export PERFORMANCE_WORKER_CONCURRENCY
export MAX_FILE_UPLOAD_SIZE
export MAX_FILE_EXTRACT_SIZE
export PORT="3214"

chown_recursive_if_writable "$PUID:$PGID" "$CONFIG_DIR"
chown_recursive_if_writable "$PUID:$PGID" "$DEFAULT_THUMBNAILS_PATH"
chown_recursive_if_writable "$PUID:$PGID" "$LIBRARY_PATH"
chown_recursive_if_writable "$PUID:$PGID" "$THUMBNAILS_PATH"

log "Configuration summary:"
log "  library_path=${LIBRARY_PATH}"
log "  thumbnails_path=${THUMBNAILS_PATH}"
log "  multiuser=${MULTIUSER}"
log "  puid:pgid=${PUID}:${PGID}"
log "  web_concurrency=${WEB_CONCURRENCY}"
log "  rails_max_threads=${RAILS_MAX_THREADS}"
log "  default_worker_concurrency=${DEFAULT_WORKER_CONCURRENCY}"
log "  performance_worker_concurrency=${PERFORMANCE_WORKER_CONCURRENCY}"
log "  max_file_upload_size=${MAX_FILE_UPLOAD_SIZE}"
log "  max_file_extract_size=${MAX_FILE_EXTRACT_SIZE}"

start_manyfold
