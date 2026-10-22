#!/usr/bin/env bash
# Assemble the pushable Joblite monorepo for Render (or any host that builds
# one Dockerfile from one git repository).
#
# Render builds a single repository; the release Dockerfile needs the two
# sibling repositories as one build context. This script exports both
# repositories at their recorded HEADs into a clean directory that already
# contains render.yaml (as render.yaml at the root) and .dockerignore, ready
# to `git add`/`git push` and connect in Render as a Blueprint.
#
# Default: both repositories must be clean; the export is taken from each
# HEAD via git archive (immutable, reproducible).
#   --worktree   export working trees instead, including uncommitted files,
#                and mark MONOREPO_SOURCE.txt as dirty. Verification only;
#                never push a dirty export.
#
# Usage:
#   ./backend/deploy/assemble-monorepo.sh [target-dir]
#   ./backend/deploy/assemble-monorepo.sh --worktree /tmp/joblite-monorepo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="$(cd "${BACKEND_DIR}/.." && pwd)"
FRONTEND_DIR="${WORKSPACE_DIR}/frontend"

MODE=clean
if [ "${1:-}" = "--worktree" ]; then
  MODE=worktree
  shift
fi
TARGET_DIR="${1:-${WORKSPACE_DIR}/joblite-monorepo}"

[ -f "${BACKEND_DIR}/mix.exs" ] || { echo "error: backend mix.exs not found at ${BACKEND_DIR}" >&2; exit 1; }
[ -f "${FRONTEND_DIR}/mix.exs" ] || { echo "error: frontend mix.exs not found at ${FRONTEND_DIR}" >&2; exit 1; }
git -C "${BACKEND_DIR}" rev-parse --git-dir >/dev/null 2>&1 || { echo "error: ${BACKEND_DIR} is not a git repository" >&2; exit 1; }
git -C "${FRONTEND_DIR}" rev-parse --git-dir >/dev/null 2>&1 || { echo "error: ${FRONTEND_DIR} is not a git repository" >&2; exit 1; }

if [ "${MODE}" = clean ]; then
  for repo in "${BACKEND_DIR}" "${FRONTEND_DIR}"; do
    if [ -n "$(git -C "${repo}" status --porcelain)" ]; then
      echo "error: ${repo} has uncommitted or untracked files:" >&2
      git -C "${repo}" status --short >&2
      echo "commit first, or rerun with --worktree for a dirty verification export" >&2
      exit 1
    fi
  done
fi

backend_sha="$(git -C "${BACKEND_DIR}" rev-parse HEAD)"
frontend_sha="$(git -C "${FRONTEND_DIR}" rev-parse HEAD)"
dirty=""
[ "${MODE}" = worktree ] && dirty="-dirty"

if [ -e "${TARGET_DIR}" ] && [ -n "$(ls -A "${TARGET_DIR}" 2>/dev/null)" ]; then
  echo "error: target ${TARGET_DIR} exists and is not empty" >&2
  exit 1
fi
mkdir -p "${TARGET_DIR}"

export_repo() {
  local repo="$1" name="$2"
  mkdir -p "${TARGET_DIR}/${name}"
  if [ "${MODE}" = clean ]; then
    git -C "${repo}" archive HEAD | tar -x -C "${TARGET_DIR}/${name}"
  else
    (cd "${repo}" && tar -cf - \
      --exclude=.git \
      --exclude=_build \
      --exclude=deps \
      --exclude=node_modules \
      --exclude=erl_crash.dump \
      --exclude=.joblite-backups \
      .) | tar -x -C "${TARGET_DIR}/${name}"
  fi
}

export_repo "${BACKEND_DIR}" backend
export_repo "${FRONTEND_DIR}" frontend

cp "${SCRIPT_DIR}/render.yaml" "${TARGET_DIR}/render.yaml"
cp "${SCRIPT_DIR}/Dockerfile.dockerignore" "${TARGET_DIR}/.dockerignore"
# Builders that default to ./Dockerfile at the repository root find the
# product Dockerfile there. It is the same file as deploy/Dockerfile: its
# build context is this repository root, which holds backend/ and frontend/.
cp "${SCRIPT_DIR}/Dockerfile" "${TARGET_DIR}/Dockerfile"

{
  echo "Joblite monorepo source record"
  echo "assembled_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "mode: ${MODE}${dirty}"
  echo "backend_sha: ${backend_sha}${dirty}"
  echo "frontend_sha: ${frontend_sha}${dirty}"
  echo "dockerfile: backend/deploy/Dockerfile (target liveview, maintenance target backend)"
  echo "blueprint: render.yaml (copied from backend/deploy/render.yaml)"
} > "${TARGET_DIR}/MONOREPO_SOURCE.txt"

git -C "${TARGET_DIR}" init -q -b main
git -C "${TARGET_DIR}" add -A
git -C "${TARGET_DIR}" -c user.name="joblite-assemble" -c user.email="assemble@joblite.invalid" \
  commit -q -m "joblite monorepo ${backend_sha:0:12}/${frontend_sha:0:12}${dirty}"

echo "assembled: ${TARGET_DIR}"
echo "record:    ${TARGET_DIR}/MONOREPO_SOURCE.txt"
echo "commit:    $(git -C "${TARGET_DIR}" rev-parse HEAD)"
echo
echo "next: review ${TARGET_DIR}, push it to your git host, then create a"
echo "Render Blueprint from that repository (render.yaml is at the root)."
