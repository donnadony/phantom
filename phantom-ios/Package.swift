// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Phantom",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Phantom", targets: ["Phantom"]),
    ],
    targets: [
        .target(name: "Phantom", path: "Sources/Phantom"),
        .testTarget(name: "PhantomTests", dependencies: ["Phantom"]),
    ]
)
