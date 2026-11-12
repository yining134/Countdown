// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Countdown",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Countdown", targets: ["Countdown"])],
    targets: [.executableTarget(name: "Countdown", resources: [.copy("Resources/StarterSkin")])]
)
