#!/bin/bash
# Rebuilds MPVKit.xcframework (LGPL, iOS) from streamyfin/MPVKit with GPL, nonfree and Samba left out.
# Needs Xcode, meson, ninja, nasm and pkg-config. Usage: scripts/build.sh [work-dir]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=${1:-$ROOT/work}
TAG=0.41.0-av5
mkdir -p "$WORK"
if [ ! -d "$WORK/sf-mpvkit" ]; then
  git clone --depth 1 --branch "$TAG" https://github.com/streamyfin/MPVKit.git "$WORK/sf-mpvkit"
fi
cd "$WORK/sf-mpvkit"
sed -i '' 's/"--enable-cross-compile", "--enable-libxml2", "--enable-nonfree",/"--enable-cross-compile", "--enable-libxml2",/' Sources/BuildScripts/XCFrameworkBuild/main.swift
sed -i '' '/^            "libsmbclient"$/d' Sources/BuildScripts/create-combined-framework.sh
cp "$ROOT"/patches/*.patch Sources/BuildScripts/patch/libmpv/
# The upstream combine step expects tvOS slices; link.sh replaces it, so its failure is expected.
make build platform=ios,isimulator || true
"$ROOT/scripts/link.sh" "$WORK"
rm -rf "$ROOT/MPVKit.xcframework"
cp -R "$WORK/out/MPVKit.xcframework" "$ROOT/MPVKit.xcframework"
