// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gd_payment_sdk",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "gd-payment-sdk",
            targets: ["gd_payment_sdk"]
        )
    ],
    dependencies: [
        // No Flutter dependency needed - it's provided by the host app
    ],
    targets: [
        // Main plugin target
        .target(
            name: "gd_payment_sdk",
            dependencies: [
                "GeideaPaymentSDK",
                "CardScan"
            ],
            path: "Classes",
            publicHeadersPath: "."
        ),

        // Your main SDK as binary target
        .binaryTarget(
            name: "GeideaPaymentSDK",
            path: "Frameworks/GeideaPaymentSDK.xcframework"
        ),

        .binaryTarget(
            name: "CardScan",
            path: "Frameworks/CardScan.xcframework"
        )
    ]
)
