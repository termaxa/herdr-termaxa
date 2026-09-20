#!/usr/bin/env bash
# Event hook for pane.agent_status_changed. When a pane goes blocked, read
# the last entry of the Termaxa record in that pane's project; if it is a
# refusal from the last 90 seconds, put the reason on the pane's state and
# open the record. Nothing else: an agent blocked for its own reasons stays
# as Herdr showed it.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
json="${HERDR_PLUGIN_EVENT_JSON:-}"
[ -n "$json" ] || exit 0
status=$(printf '%s' "$json" | field agent_status)
[ "$status" = "blocked" ] || exit 0
pane=$(printf '%s' "$json" | field pane_id)
[ -n "$pane" ] || exit 0
cwd=$(pane_cwd "$pane"); [ -n "$cwd" ] || exit 0
proj=$(project_of "$cwd")
[ -d "$proj/.termaxa" ] || exit 0
command -v termaxa >/dev/null || exit 0
last=$(cd "$proj" && termaxa log -n 1 --json 2>/dev/null | tail -n 1)
[ -n "$last" ] || exit 0
decision=$(printf '%s' "$last" | field decision)
case "$decision" in deny|ask) ;; *) exit 0 ;; esac
ts_ms=$(printf '%s' "$last" | sed -n 's/.*"ts_ms":\([0-9]*\).*/\1/p')
now_ms=$(( $(date +%s) * 1000 ))
[ -n "$ts_ms" ] && [ $(( now_ms - ts_ms )) -le 90000 ] || exit 0
# Once per entry: report-agent itself changes the pane's state.
mark="${XDG_STATE_HOME:-$HOME/.local/state}/termaxa-herdr"
mkdir -p "$mark"
[ "$(cat "$mark/$pane" 2>/dev/null)" = "$ts_ms" ] && exit 0
printf '%s' "$ts_ms" > "$mark/$pane"
reason=$(printf '%s' "$last" | field reason)
cmd=$(printf '%s' "$last" | field command)
label=$(herdr pane get "$pane" 2>/dev/null | field agent); [ -n "$label" ] || label="agent"
herdr pane report-agent "$pane" --source termaxa --agent "$label" --state blocked \
  --message "termaxa ${decision}: ${cmd:0:60} — ${reason:0:140}" >/dev/null 2>&1 || true
ws=$(herdr pane get "$pane" 2>/dev/null | field workspace_id)
herdr plugin pane open --plugin termaxa.gate --entrypoint record --placement overlay ${ws:+--workspace "$ws"} >/dev/null 2>&1 || true
