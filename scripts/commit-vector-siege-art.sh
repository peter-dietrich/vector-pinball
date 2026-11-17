#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
ASSET="Resources/VectorSiege_Pinball_Background.png"
SOURCE="${1:-$HOME/Downloads/VectorSiege_Pinball_Background.png}"
if [[ ! -f "$SOURCE" ]]; then
  echo "Cannot find artwork at: $SOURCE"
  echo "Save the provided PNG in Downloads, then rerun this script."
  exit 1
fi
mkdir -p Resources
cp "$SOURCE" "$ASSET"
if ! file "$ASSET" | grep -q "PNG image data"; then
  echo "The supplied asset is not a PNG." >&2
  exit 1
fi
EXPECTED="162b85ddfe69129b71de5d56744b147ec0fe234e4b8d6d5391665cfa82979335"
ACTUAL="$(shasum -a 256 "$ASSET" | awk '{print $1}')"
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "Artwork SHA-256 does not match the approved image. Expected $EXPECTED; got $ACTUAL" >&2
  exit 1
fi
git add "$ASSET"
if ! git diff --cached --quiet -- "$ASSET"; then
  git commit -m "Add original Vector Siege pinball table artwork"
fi
git push origin main
echo "Artwork is now committed on main: $(git rev-parse --short HEAD)"
echo "No artwork import is required on any future clone or Fun City build."
