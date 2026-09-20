#!/usr/bin/env bash
# Action: open the record pane for the current workspace as an overlay.
set -euo pipefail
exec herdr plugin pane open --plugin termaxa.gate --entrypoint record --placement overlay ${HERDR_WORKSPACE_ID:+--workspace "$HERDR_WORKSPACE_ID"}
