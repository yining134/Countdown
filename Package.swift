// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Countdown",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Countdown", targets: ["Countdown"])],
    targets: [
        .executableTarget(
            name: "Countdown",
            resources: [
                .copy("Resources/StarterSkin"), .copy("Resources/PixelChick"),
                .copy("Resources/SteamJourney"), .copy("Resources/BlackCat"),
                .copy("Resources/Fonts"),
                .process("Resources/en.lproj"), .process("Resources/zh-Hans.lproj"),
            ])
    ]
)
