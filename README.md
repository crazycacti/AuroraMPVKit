# AuroraMPVKit

Swift package with the mpv players used by Aurora on iPhone, iPad and Apple TV. Each player is one dynamic framework built from LGPL sources without GPL components.

## Products

| Product | Platform | Framework | Module | Built from |
| --- | --- | --- | --- | --- |
| `AuroraMPV` | iOS, iOS Simulator | `MPVKit.xcframework` | `MPVKit` | streamyfin/MPVKit 0.41.0-av5 |
| `AuroraTVMPV` | tvOS, tvOS Simulator | `Libmpv.xcframework` | `Libmpv` | mpvkit/MPVKit 1.0.0 |

The binaries target iOS 18.0 and tvOS 18.0. Device slices are arm64; simulator slices are arm64 and x86_64.

## Swift Package Manager

Pin by revision:

```swift
.package(url: "https://github.com/crazycacti/AuroraMPVKit.git", revision: "<commit>")
```

Then depend on `AuroraMPV` for iOS or `AuroraTVMPV` for tvOS. Each product re-exports its framework module.

## Rebuilding

### iOS: MPVKit.xcframework

Needs Xcode, git, make, meson, ninja, nasm and pkg-config.

```sh
scripts/build.sh [work-dir]
```

The work directory defaults to `work/`. The script:

1. Clones streamyfin/MPVKit at tag `0.41.0-av5`.
2. Removes `--enable-nonfree` from the FFmpeg configure flags and drops `libsmbclient` from the combined framework.
3. Copies `patches/0007-avfoundation-pixel-aspect-ratio.patch` and `patches/0008-avfoundation-subtitle-layer-layout.patch` into the upstream libmpv patch folder.
4. Runs the upstream build for `ios` and `isimulator`, then `scripts/link.sh` to link the static libraries into one dynamic framework.
5. Replaces `MPVKit.xcframework` in the repo.

To relink an existing build without rebuilding:

```sh
scripts/link.sh <work-dir>
```

The result is written to `<work-dir>/out/MPVKit.xcframework` and is not copied into the repo.

### Apple TV: Libmpv.xcframework

Needs Xcode. `tvos-sources.txt` lists each mpvkit 1.0.0 xcframework zip with its URL and SHA-256 checksum. Download every zip, verify its checksum, and unzip them into one folder:

```sh
mkdir -p ../mpvkit-tvos-artifacts
grep -v '^#' tvos-sources.txt | while read -r name url sum; do
  curl -fL -o "../mpvkit-tvos-artifacts/$name.zip" "$url"
  echo "$sum  ../mpvkit-tvos-artifacts/$name.zip" | shasum -a 256 -c -
  unzip -q -o "../mpvkit-tvos-artifacts/$name.zip" -d ../mpvkit-tvos-artifacts
done
scripts/link-tvos.sh ../mpvkit-tvos-artifacts [work-dir]
```

The work directory defaults to `work-tvos/` and is deleted at the start of each run, so keep the artifacts outside it. The script links the tvOS slices of the static libraries into one dynamic framework and replaces `Libmpv.xcframework` in the repo.

## License

The frameworks contain mpv, FFmpeg and other libraries under LGPL-2.1-or-later or LGPL-3.0, and libraries under permissive licenses. They are built without GPL components. License texts are in `licenses/`; the LGPL-3.0 text refers to the GPL-3.0 text, so both are included. Notices for every bundled library are in `THIRD-PARTY-NOTICES.txt`.

## Source

iOS: [streamyfin/MPVKit](https://github.com/streamyfin/MPVKit) at tag `0.41.0-av5`, with the changes in `scripts/build.sh` and the patches in `patches/`.

Apple TV: [mpvkit/MPVKit](https://github.com/mpvkit/MPVKit) at tag `1.0.0`, and the library build repositories at the tags in `tvos-sources.txt`:

| Repository | Tag |
| --- | --- |
| [mpvkit/gnutls-build](https://github.com/mpvkit/gnutls-build) | `3.8.11` |
| [mpvkit/lcms2-build](https://github.com/mpvkit/lcms2-build) | `2.17.0` |
| [mpvkit/libass-build](https://github.com/mpvkit/libass-build) | `0.17.5` |
| [mpvkit/libbluray-build](https://github.com/mpvkit/libbluray-build) | `1.4.0` |
| [mpvkit/libdav1d-build](https://github.com/mpvkit/libdav1d-build) | `1.5.3` |
| [mpvkit/libdovi-build](https://github.com/mpvkit/libdovi-build) | `3.3.2` |
| [mpvkit/libplacebo-build](https://github.com/mpvkit/libplacebo-build) | `7.360.1` |
| [mpvkit/libshaderc-build](https://github.com/mpvkit/libshaderc-build) | `2025.5.0` |
| [mpvkit/libuavs3d-build](https://github.com/mpvkit/libuavs3d-build) | `1.2.1-fix` |
| [mpvkit/libuchardet-build](https://github.com/mpvkit/libuchardet-build) | `0.0.8` |
| [mpvkit/moltenvk-build](https://github.com/mpvkit/moltenvk-build) | `1.4.2` |
| [mpvkit/openssl-build](https://github.com/mpvkit/openssl-build) | `3.3.5` |

Each build repository names the upstream source release it compiles.
