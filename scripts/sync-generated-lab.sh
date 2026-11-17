#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f Assets/Scenes/PhysicsLab.unity ]]; then
  echo "PhysicsLab.unity not found. In Unity, first select Fun City > Pinball > Build Physics Lab Scene."
  exit 1
fi
git add Assets/Scenes Assets/PhysicsMaterials Assets/Editor Assets/Scripts Assets/Tests
if git diff --cached --quiet; then
  echo "All generated Unity assets are already tracked in Git."
else
  git commit -m "Commit generated Unity physics lab scene and physics materials"
fi
git push origin main
echo "Physics lab scene, source files, and metadata are synced to GitHub."
