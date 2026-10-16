// swift-tools-version: 6.0
import PackageDescription


let package = Package(
    name: "meta-display-app",
    platforms: [
        .iOS(.v17) // ios version
    ],
    dependencies: [
        // Meta Wearables DAT iOS Package
        .package(url: "https://github.com/facebook/meta-wearables-dat-ios", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "meta-display-app",
            dependencies: [
                .product(name: "MWDATCore", package: "meta-wearables-dat-ios"),
                .product(name: "MWDATCamera", package: "meta-wearables-dat-ios")
            ]
        )
    ]
)
