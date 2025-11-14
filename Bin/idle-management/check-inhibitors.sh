#!/bin/bash
#
# Check if any of the specified inhibitor apps are running
# SECURITY: Updated to accept separate arguments instead of comma-separated string (VULN-002)
# Usage: check-inhibitors.sh app1 app2 app3
# Exit code 0: at least one app is running (should inhibit)
# Exit code 1: no apps are running (can proceed)
#

# If no apps specified, exit with 1 (no inhibitors)
if [ $# -eq 0 ]; then
  exit 1
fi

# Check each app (each is a separate argument now)
for app in "$@"; do
  # SECURITY: Validate app name contains only safe characters
  if ! [[ "$app" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    # Invalid characters detected, skip this app
    continue
  fi

  # SECURITY: Limit length to prevent abuse
  if [ ${#app} -gt 255 ]; then
    continue
  fi

  # Skip empty app names
  if [ -z "$app" ]; then
    continue
  fi

  # Check if process is running using pgrep
  # -x: exact match on process name
  # --: end of options, treat everything after as pattern (prevents option injection)
  if pgrep -x -- "$app" > /dev/null 2>&1; then
    # App is running, inhibit action
    exit 0
  fi
done

# No inhibitor apps found running
exit 1
