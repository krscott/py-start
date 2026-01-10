#!/usr/bin/env sh
set -eu

isort .
black .

for file in $(git ls-files '*.nix'); do
    nix fmt "$file"
done
