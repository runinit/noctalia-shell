#!/bin/bash
#
# Check if any of the specified inhibitor apps are running
# Usage: check-inhibitors.sh "app1,app2,app3"
# Exit code 0: at least one app is running (should inhibit)
# Exit code 1: no apps are running (can proceed)
#

# Get the comma-separated list of apps
apps="$1"

# If no apps specified, exit with 1 (no inhibitors)
if [ -z "$apps" ]; then
  exit 1
fi

# Split by comma and check each app
IFS=',' read -ra APP_ARRAY <<< "$apps"
for app in "${APP_ARRAY[@]}"; do
  # Trim whitespace
  app=$(echo "$app" | xargs)

  # Skip empty app names
  if [ -z "$app" ]; then
    continue
  fi

  # Check if process is running using pgrep
  # -x: exact match on process name
  if pgrep -x "$app" > /dev/null 2>&1; then
    # App is running, inhibit action
    exit 0
  fi
done

# No inhibitor apps found running
exit 1
