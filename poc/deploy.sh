#!/usr/bin/env bash
# Deploy the pushed branch to the deploy clone on the deploy host, then rebuild and start the containers.
# Run this script on the development machine after you push the branch.
# The script does not read, copy or print backend/config/.env.
set -euo pipefail

HOST="${DEPLOY_HOST:-mini.local}"
DIR="${DEPLOY_DIR:-deploy/open-wearables}"  # relative to the home directory on the deploy host
BRANCH="${DEPLOY_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

git fetch -q origin "$BRANCH"
SHA="$(git rev-parse "origin/$BRANCH")"
if [ "$(git rev-parse HEAD)" != "$SHA" ]; then
  echo "Local HEAD is not origin/$BRANCH. Push the branch first." >&2
  exit 1
fi

echo "Deploy $BRANCH at ${SHA:0:8} to $HOST:~/$DIR"
ssh "$HOST" bash -s -- "$DIR" "$BRANCH" "$SHA" <<'REMOTE'
set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
cd "$HOME/$1"
test -f backend/config/.env || { echo "backend/config/.env is missing in the deploy clone." >&2; exit 1; }
git fetch -q origin "$2"
git checkout -q "$2"
git merge -q --ff-only "origin/$2"
test "$(git rev-parse HEAD)" = "$3" || { echo "The deploy clone HEAD is not $3." >&2; exit 1; }
docker compose up -d --build --remove-orphans
docker compose ps --format 'table {{.Service}}\t{{.State}}\t{{.Status}}'
REMOTE
