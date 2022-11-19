#!/bin/bash

PYTHONPATH="$HOME/.local/bin:/opt/program:$PYTHONPATH"
PATH="$HOME/.local/bin:/opt/program:$PATH"
PYTHONUNBUFFERED=TRUE
PYTHONDONTWRITEBYTECODE=TRUE
LC_ALL=C.UTF-8
LANG=C.UTF-8

# Forwards SIGTERM to server to gracefully kill it
# Standard behavior is to ignore signal while process is running
_term() {
  echo "Caught SIGTERM signal!"
  echo "killing $child"
  kill -TERM "$child" 2>/dev/null
  wait "$child"
}

# Catching SIGINT will ensure that we have the same behavior in terminal (Ctrl-C)
# and in docker SIGTERM when stopping the server.
trap _term SIGTERM
trap _term SIGINT

echo "Running Server on host $HOSTNAME:$PORT... with '$@'"
uvicorn server.main:app --host "$HOSTNAME" --port "$PORT" $@ &


child=$!
wait "$child"