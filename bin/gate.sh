#!/usr/bin/env bash
# Action: start an agent under the gate in a new pane beside the current one.
#   gate.sh claude   → termaxa wrap -- claude   (the wrapper; measured on Claude Code)
#   gate.sh codex    → termaxa init --codex; codex   (Codex ignores the wrapper's shell; its hook is the way in)
set -euo pipefail
. "$(dirname "$0")/lib.sh"
agent="${1:-claude}"
command -v termaxa >/dev/null || { echo "termaxa is not on PATH: https://github.com/termaxa/termaxa#install" >&2; exit 1; }
command -v "$agent" >/dev/null || { echo "$agent is not on PATH" >&2; exit 1; }
pane="${HERDR_PANE_ID:-}"
ws="${HERDR_WORKSPACE_ID:-}"
if [ -z "$pane" ]; then
  pane=$(herdr pane list ${ws:+--workspace "$ws"} | field pane_id)
fi
[ -n "$pane" ] || { echo "no pane to split from" >&2; exit 1; }
cwd=$(pane_cwd "$pane"); [ -n "$cwd" ] || cwd=$(workspace_cwd "$ws"); [ -n "$cwd" ] || cwd="$PWD"
before=$(herdr pane list ${ws:+--workspace "$ws"} | grep -o '"pane_id":"[^"]*"' | sort -u)
herdr pane split "$pane" --direction right --cwd "$cwd" --focus >/dev/null
after=$(herdr pane list ${ws:+--workspace "$ws"} | grep -o '"pane_id":"[^"]*"' | sort -u)
new=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -n 1 | cut -d'"' -f4)
[ -n "$new" ] || { echo "could not find the new pane" >&2; exit 1; }
case "$agent" in
  claude) herdr pane run "$new" "termaxa wrap -- claude" ;;
  codex)  herdr pane run "$new" "termaxa init --codex >/dev/null 2>&1; codex" ;;
  *)      herdr pane run "$new" "termaxa wrap -- $agent" ;;
esac
herdr pane rename "$new" "termaxa · $agent" >/dev/null 2>&1 || true
