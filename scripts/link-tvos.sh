#!/bin/bash
# Links the LGPL static libraries of mpvkit/MPVKit 1.0.0 (tvOS slices) into one dynamic Libmpv.xcframework,
# so the Apple TV app ships mpv and FFmpeg as a replaceable library instead of linking them into its binary.
# Input: a folder holding the unzipped xcframeworks listed in tvos-sources.txt (check each zip's sha256).
# Usage: scripts/link-tvos.sh <artifacts-dir> [work-dir]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=${1:?usage: link-tvos.sh <artifacts-dir> [work-dir]}
WORK=${2:-$ROOT/work-tvos}
OUT=$WORK/out
rm -rf "$WORK"; mkdir -p "$OUT"

LIBS=(
  Libavformat Libavfilter Libavcodec Libswscale Libswresample Libavutil Libavdevice
  Libass Libharfbuzz Libfribidi Libfreetype Libunibreak
  Libplacebo Libdovi lcms2 Libshaderc_combined MoltenVK
  Libdav1d Libuavs3d Libuchardet Libbluray
  gnutls hogweed nettle gmp Libssl Libcrypto
)

archive() {
  local name=$1 slice=$2
  local xc
  xc=$(ls -d "$SRC"/*/"$name".xcframework "$SRC/$name.xcframework" 2>/dev/null | head -1)
  [ -n "$xc" ] || { echo "missing $name.xcframework" >&2; exit 1; }
  local dir="$xc/$slice"
  if [ -f "$dir/$name.framework/$name" ]; then echo "$dir/$name.framework/$name"
  else ls "$dir"/*.a | head -1
  fi
}

link_slice() {
  local slice=$1 arch=$2 sdk=$3 target=$4 out=$5
  local thin=$WORK/$slice-$arch
  mkdir -p "$thin"
  local args=()
  for name in Libmpv "${LIBS[@]}"; do
    local a; a=$(archive "$name" "$slice")
    lipo "$a" -thin "$arch" -output "$thin/$name.a" 2>/dev/null || cp "$a" "$thin/$name.a"
    [ "$name" = Libmpv ] || args+=("$thin/$name.a")
  done
  nm -gU "$thin/Libmpv.a" 2>/dev/null | awk '$2 ~ /[TDS]/ && $3 ~ /^_mpv_/ {print $3}' | sort -u > "$WORK/exports.txt"
  xcrun -sdk "$sdk" clang++ -dynamiclib -target "$target" -isysroot "$(xcrun -sdk "$sdk" --show-sdk-path)" \
    -Wl,-force_load,"$thin/Libmpv.a" "${args[@]}" \
    -Wl,-exported_symbols_list,"$WORK/exports.txt" -Wl,-dead_strip \
    -install_name @rpath/Libmpv.framework/Libmpv -compatibility_version 1 -current_version 1 \
    -framework AVFoundation -framework AudioToolbox -framework CoreAudio -framework CoreFoundation \
    -framework CoreMedia -framework CoreVideo -framework Metal -framework QuartzCore -framework VideoToolbox \
    -framework Security -framework IOSurface -framework UIKit -framework Foundation -framework CoreGraphics \
    -framework CoreText -framework CoreImage -framework OpenGLES -lbz2 -liconv -lxml2 -lz -lresolv -lexpat \
    -o "$out"
}

make_framework() {
  local dir=$1 binary=$2 slice=$3
  local fw=$dir/Libmpv.framework
  local upstream; upstream=$(dirname "$(archive Libmpv "$slice")")
  mkdir -p "$fw"
  cp "$binary" "$fw/Libmpv"
  cp -R "$upstream/Headers" "$upstream/Modules" "$fw/"
  cat > "$fw/Info.plist" <<'P'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Libmpv</string>
  <key>CFBundleIdentifier</key><string>com.gosynrgy.aurora.libmpv</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Libmpv</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>18.0</string>
</dict>
</plist>
P
}

DEV=tvos-arm64_arm64e
SIM=tvos-arm64_x86_64-simulator
link_slice $DEV arm64 appletvos arm64-apple-tvos18.0 "$OUT/device.dylib"
link_slice $SIM arm64 appletvsimulator arm64-apple-tvos18.0-simulator "$OUT/sim-arm64.dylib"
link_slice $SIM x86_64 appletvsimulator x86_64-apple-tvos18.0-simulator "$OUT/sim-x86_64.dylib"
lipo -create "$OUT/sim-arm64.dylib" "$OUT/sim-x86_64.dylib" -output "$OUT/sim.dylib"

make_framework "$OUT/device" "$OUT/device.dylib" $DEV
make_framework "$OUT/sim" "$OUT/sim.dylib" $SIM
rm -rf "$OUT/Libmpv.xcframework"
xcodebuild -create-xcframework -framework "$OUT/device/Libmpv.framework" -framework "$OUT/sim/Libmpv.framework" \
  -output "$OUT/Libmpv.xcframework"
rm -rf "$ROOT/Libmpv.xcframework"
cp -R "$OUT/Libmpv.xcframework" "$ROOT/Libmpv.xcframework"
