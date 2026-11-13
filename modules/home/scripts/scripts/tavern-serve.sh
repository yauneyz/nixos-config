#!/usr/bin/env bash
set -euo pipefail
# The packaged orchestrator starts textgen (model UI + API) and SillyTavern.
exec tavern-stack "$@"
