#!/usr/bin/env bash
# Build entry point for the Joblite Docker images.
#
# Resolves the two sibling repositories relative to this script and builds
# both image targets from the workspace parent context:
#   joblite-liveview:<build-id>  - product image (Phoenix endpoint + LiveView)
#   joblite-backend:<build-id>   - one-off maintenance image (same release)
#
# Usage:
#   ./deploy/build-images.sh [build-id]
#   JOBLITE_BUILD_ID=... ./deploy/build-images.sh   # explicit id via env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="$(cd "${BACKEND_DIR}/.." && pwd)"
FRONTEND_DIR="${WORKSPACE_DIR}/frontend"

[ -f "${BACKEND_DIR}/mix.exs" ] || { echo "error: backend mix.exs not found at ${BACKEND_DIR}" >&2; exit 1; }
[ -f "${FRONTEND_DIR}/mix.exs" ] || { echo "error: frontend mix.exs not found at ${FRONTEND_DIR}" >&2; exit 1; }

frontend_sha="$(git -C "${FRONTEND_DIR}" rev-parse --short=12 HEAD 2>/dev/null || echo nogit)"
backend_sha="$(git -C "${BACKEND_DIR}" rev-parse --short=12 HEAD 2>/dev/null || echo nogit)"
dirty=""
git -C "${FRONTEND_DIR}" diff --quiet 2>/dev/null || dirty="-dirty"
git -C "${BACKEND_DIR}" diff --quiet 2>/dev/null || dirty="-dirty"

build_id="${1:-${JOBLITE_BUILD_ID:-$(date -u +%Y%m%d)-f${frontend_sha}-b${backend_sha}${dirty}}}"
platform="$(docker version -f '{{.Server.Os}}/{{.Server.Arch}}')"

echo "context:    ${WORKSPACE_DIR}"
echo "revisions:  backend ${backend_sha}, frontend ${frontend_sha}${dirty}"
echo "platform:   ${platform}"
echo "build id:   ${build_id}"
echo

build() {
  local target="$1" image="$2"
  echo "==> docker build --target ${target} -t ${image}:${build_id}"
  docker build \
    --platform "${platform}" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    --target "${target}" \
    -t "${image}:${build_id}" \
    "${WORKSPACE_DIR}"
}

build backend joblite-backend
build liveview joblite-liveview

echo
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}' \
  | grep -E "joblite-(backend|liveview):${build_id}" || true
echo
echo "Built joblite-liveview:${build_id} (product) and joblite-backend:${build_id} (maintenance)."
echo "Recorded id: ${build_id}"
