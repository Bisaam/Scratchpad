// swift-tools-version: 6.0
import PackageDescription

// This build machine has only the Command Line Tools installed (no full
// Xcode.app), so the Swift Testing framework isn't on the default search
// paths the way it would be with a real Xcode toolchain. These flags point
// the compiler and linker at the CLT's copy directly. Harmless no-ops once
// a machine with full Xcode builds this package. See JOURNAL.md.
let testingFrameworkSearchPath = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let testingPluginPath = "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"

let testSwiftSettings: [SwiftSetting] = [
    .unsafeFlags(["-F", testingFrameworkSearchPath, "-plugin-path", testingPluginPath])
]
let testingInteropLibraryPath = "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"

let testLinkerSettings: [LinkerSetting] = [
    .unsafeFlags([
        "-F", testingFrameworkSearchPath,
        "-Xlinker", "-rpath", "-Xlinker", testingFrameworkSearchPath,
        "-Xlinker", "-rpath", "-Xlinker", testingInteropLibraryPath,
    ])
]

let package = Package(
    name: "Scratchpad",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Scratchpad",
            path: "Sources/Scratchpad",
            exclude: ["Resources/Info.plist"],
            resources: [.copy("Resources/PencilCursor.png")]
        ),
        .testTarget(
            name: "DrawingTests",
            dependencies: ["Scratchpad"],
            path: "Tests/DrawingTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Scratchpad"],
            path: "Tests/PersistenceTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Scratchpad"],
            path: "Tests/SettingsTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "HotkeyTests",
            dependencies: ["Scratchpad"],
            path: "Tests/HotkeyTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "RenderingTests",
            dependencies: ["Scratchpad"],
            path: "Tests/RenderingTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "OverlayTests",
            dependencies: ["Scratchpad"],
            path: "Tests/OverlayTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
    ]
)
