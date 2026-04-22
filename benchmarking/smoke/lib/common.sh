#!/usr/bin/env bash
# Shared helpers for GuideLLM / inference smoke tests.
# shellcheck shell=bash

set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $*"; }
fail() { echo -e "${RED}FAIL${NC}: $*" >&2; }
warn() { echo -e "${YELLOW}WARN${NC}: $*"; }
info() { echo -e "INFO: $*"; }

# Normalize base URL: strip trailing slashes and trailing /v1 (matches GuideLLM OpenAI backend behavior).
normalize_target() {
  local t="${1:?target required}"
  t="${t%/}"
  case "$t" in
    */v1) t="${t%/v1}" ;;
  esac
  echo "$t"
}

curl_headers_auth() {
  if [[ -n "${SMOKE_API_KEY:-}" ]]; then
    echo "-H" "Authorization: Bearer ${SMOKE_API_KEY}"
  fi
}

# Args: URL [extra curl args...]
http_get() {
  local url="$1"
  shift
  local insecure=()
  [[ "${SMOKE_INSECURE:-0}" == "1" ]] && insecure=(-k)
  curl -fsS "${insecure[@]}" --max-time "${SMOKE_CURL_TIMEOUT:-20}" "$@" "$url"
}

http_get_code() {
  local url="$1"
  shift
  local insecure=()
  [[ "${SMOKE_INSECURE:-0}" == "1" ]] && insecure=(-k)
  curl -sS -o /dev/null -w "%{http_code}" "${insecure[@]}" --max-time "${SMOKE_CURL_TIMEOUT:-20}" "$@" "$url"
}

http_post_json() {
  local url="$1"
  local body="$2"
  shift 2
  local insecure=()
  [[ "${SMOKE_INSECURE:-0}" == "1" ]] && insecure=(-k)
  curl -fsS "${insecure[@]}" --max-time "${SMOKE_CURL_TIMEOUT:-120}" \
    -H "Content-Type: application/json" \
    "$@" \
    -d "$body" \
    "$url"
}
