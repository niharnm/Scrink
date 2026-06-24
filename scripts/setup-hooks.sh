#!/bin/sh
# Point git at the repo's tracked hooks (.githooks). Run once per clone.
set -e
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
echo "✓ Hooks enabled. Direct pushes to main are now blocked locally."
echo "  Work on a branch and open a PR; bypass in emergencies with: git push --no-verify"
