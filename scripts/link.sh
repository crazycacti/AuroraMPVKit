#!/bin/bash
# Links the LGPL static libraries into one dynamic MPVKit.xcframework for iOS (no Samba).
set -euo pipefail
WORK=${1:?usage: link.sh <work-dir>}
D=$WORK/sf-mpvkit/dist
OUT=$WORK/out
rm -rf "$OUT"; mkdir -p "$OUT"
nm -gU "$D/libmpv/ios/thin/arm64/lib/libmpv.a" 2>/dev/null | awk '$2 ~ /[TDS]/ && $3 ~ /^_mpv_/ {print $3}' | sort -u > "$OUT/exports.txt"

LIBS=(
  FFmpeg/{libavformat,libavfilter,libavcodec,libswscale,libswresample,libavutil,libavdevice}
  libass/libass libharfbuzz/libharfbuzz libfribidi/libfribidi libfreetype/libfreetype libunibreak/libunibreak
  libplacebo/libplacebo libdovi/libdovi lcms2/liblcms2 libshaderc/libshaderc_combined vulkan/libMoltenVK
  libdav1d/libdav1d libuavs3d/libuavs3d libuchardet/libuchardet libbluray/libbluray
  gnutls/libgnutls nettle/libhogweed nettle/libnettle gmp/libgmp openssl/libssl openssl/libcrypto
)

link_slice() {
  local plat=$1 arch=$2 sdk=$3 target=$4
  local args=()
  for entry in "${LIBS[@]}"; do
    local dir=${entry%%/*} name=${entry#*/}
    local f="$D/$dir/$plat/thin/$arch/lib/$name.a"
    [ -f "$f" ] || { echo "missing $f"; exit 1; }
    args+=("$f")
  done
  xcrun -sdk "$sdk" clang++ -dynamiclib -target "$target" -isysroot "$(xcrun -sdk "$sdk" --show-sdk-path)" \
    -Wl,-force_load,"$D/libmpv/$plat/thin/$arch/lib/libmpv.a" "${args[@]}" \
    -Wl,-exported_symbols_list,"$OUT/exports.txt" -Wl,-dead_strip \
    -install_name @rpath/MPVKit.framework/MPVKit -compatibility_version 1 -current_version 1 \
    -framework AVFoundation -framework AudioToolbox -framework CoreAudio -framework CoreFoundation \
    -framework CoreMedia -framework CoreVideo -framework Metal -framework QuartzCore -framework VideoToolbox \
    -framework Security -framework IOSurface -framework UIKit -framework Foundation -framework CoreGraphics \
    -framework CoreText -framework CoreImage -framework OpenGLES -lbz2 -liconv -lxml2 -lz -lresolv -lexpat \
    -o "$OUT/$plat-$arch.dylib"
}

make_framework() {
  local dir=$1 binary=$2
  local fw="$dir/MPVKit.framework"
  mkdir -p "$fw/Headers/mpv" "$fw/Modules"
  cp "$binary" "$fw/MPVKit"
  cp "$D"/libmpv/ios/thin/arm64/include/mpv/*.h "$fw/Headers/mpv/"
  cat > "$fw/Headers/MPVKit.h" <<'H'
#include "mpv/client.h"
#include "mpv/render.h"
#include "mpv/render_gl.h"
#include "mpv/stream_cb.h"
H
  cat > "$fw/Modules/module.modulemap" <<'M'
framework module MPVKit {
    umbrella header "MPVKit.h"
    export *
    module * { export * }
}
M
  cat > "$fw/Info.plist" <<'P'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>MPVKit</string>
    <key>CFBundleIdentifier</key><string>com.gosynrgy.aurora.mpvkit</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>MPVKit</string>
    <key>CFBundlePackageType</key><string>FMWK</string>
    <key>CFBundleShortVersionString</key><string>0.41.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>MinimumOSVersion</key><string>18.0</string>
</dict>
</plist>
P
}

link_slice ios arm64 iphoneos arm64-apple-ios18.0
link_slice isimulator arm64 iphonesimulator arm64-apple-ios18.0-simulator
link_slice isimulator x86_64 iphonesimulator x86_64-apple-ios18.0-simulator
lipo -create "$OUT/isimulator-arm64.dylib" "$OUT/isimulator-x86_64.dylib" -output "$OUT/isimulator.dylib"

make_framework "$OUT/device" "$OUT/ios-arm64.dylib"
make_framework "$OUT/simulator" "$OUT/isimulator.dylib"
xcodebuild -create-xcframework \
  -framework "$OUT/device/MPVKit.framework" \
  -framework "$OUT/simulator/MPVKit.framework" \
  -output "$OUT/MPVKit.xcframework"
