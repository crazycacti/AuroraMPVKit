// swift-tools-version:5.9
// LGPL players for Aurora. iOS: streamyfin/MPVKit 0.41.0-av5 (mpv v0.41.0 with vo_avfoundation, FFmpeg n8.1),
// rebuilt with scripts/build.sh. tvOS: mpvkit/MPVKit 1.0.0 LGPL libraries linked into one dynamic Libmpv
// with scripts/link-tvos.sh.

import PackageDescription

let package = Package(
    name: "AuroraMPV",
    platforms: [.iOS(.v17), .tvOS(.v17)],
    products: [
        .library(name: "AuroraMPV", targets: ["AuroraMPV"]),
        .library(name: "AuroraTVMPV", targets: ["AuroraTVMPV"]),
    ],
    targets: [
        .target(
            name: "AuroraMPV",
            dependencies: ["MPVKit"],
            path: "Sources/AuroraMPV",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
                .linkedLibrary("resolv"),
                .linkedLibrary("expat"),
            ]
        ),
        .binaryTarget(name: "MPVKit", path: "MPVKit.xcframework"),
        .target(name: "AuroraTVMPV", dependencies: ["Libmpv"], path: "Sources/AuroraTVMPV"),
        .binaryTarget(name: "Libmpv", path: "Libmpv.xcframework"),
    ]
)
