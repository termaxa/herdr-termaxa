#!/usr/bin/env bash
# Pane: the workspace project's Termaxa record, following. `termaxa log -f`
# prints the last entries and then each one as it is written.
. "$(dirname "$0")/lib.sh"
cwd=""
[ -n "${HERDR_PANE_ID:-}" ] && cwd=$(pane_cwd "$HERDR_PANE_ID")
[ -n "$cwd" ] || [ -z "${HERDR_WORKSPACE_ID:-}" ] || cwd=$(workspace_cwd "$HERDR_WORKSPACE_ID")
[ -n "$cwd" ] && cd "$(project_of "$cwd")" 2>/dev/null
have_termaxa || { echo "termaxa not found: install it or put it on PATH"; exec sleep 5; }
if [ ! -d .termaxa ]; then
  echo "no .termaxa/ in $(pwd): run 'termaxa init' here first (or wrap an agent from this workspace)."
  exec sleep 5
fi
exec "$TERMAXA" log --follow -n 30
