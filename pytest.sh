#!/usr/bin/env sh
set -eu

export PYTHONPATH="''${PYTHONPATH:-}:."
pytest
