#!/usr/bin/env bash
# Action: open the record pane for the current workspace as an overlay.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
have_herdr || { echo "herdr not found: HERDR_BIN_PATH unset and not on PATH" >&2; exit 1; }
# An overlay targets the active pane and takes no --workspace.
exec "$HERDR" plugin pane open --plugin termaxa.gate --entrypoint record --placement overlay
