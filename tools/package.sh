#!/bin/sh
# Builds dist/ControllerSpellWheel-<version>.zip: a ControllerSpellWheel/
# folder with the TOC, the files it lists, the licence and the README.
set -e
cd "$(dirname "$0")/.."
name=ControllerSpellWheel
version=$(sed -n 's/^## Version:[[:space:]]*//p' "$name.toc" | tr -d '\r')
files=$(grep -v '^#' "$name.toc" | grep -v '^[[:space:]]*$' | tr -d '\r')
stage=$(mktemp -d)
mkdir "$stage/$name"
cp "$name.toc" LICENSE README.md $files "$stage/$name/"
mkdir -p dist
rm -f "dist/$name-$version.zip"
(cd "$stage" && zip -qr - "$name") > "dist/$name-$version.zip"
rm -rf "$stage"
echo "dist/$name-$version.zip"
