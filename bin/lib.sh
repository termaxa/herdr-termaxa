#!/usr/bin/env bash
# Shared helpers. Herdr prints JSON; these pull one string field out of it
# without needing python or jq on the machine.
field() { # field NAME <<< JSON  → first value of "NAME":"…"
  sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p" | head -n 1
}
pane_cwd() { # pane_cwd PANE_ID → the pane's cwd (foreground first), or empty
  local json; json=$(herdr pane get "$1" 2>/dev/null) || return 1
  local cwd; cwd=$(printf '%s' "$json" | field foreground_cwd)
  [ -n "$cwd" ] || cwd=$(printf '%s' "$json" | field cwd)
  printf '%s' "$cwd"
}
workspace_cwd() { # workspace_cwd WS_ID → the workspace's cwd, or empty
  herdr workspace get "$1" 2>/dev/null | field cwd
}
project_of() { # project_of DIR → nearest ancestor with .termaxa/, or DIR
  local d="$1"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ -d "$d/.termaxa" ] && { printf '%s' "$d"; return; }
    d=$(dirname "$d")
  done
  printf '%s' "$1"
}
