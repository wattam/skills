#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
destination="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills"

mkdir -p -- "$destination"
rm -rf -- "$destination/claude-dagu-pipeline"
find development-pipeline dagu/skills utility -type f -name SKILL.md -print0 |
    while IFS= read -r -d '' skill_file; do
        cp -R -- "${skill_file%/*}" "$destination/"
    done
