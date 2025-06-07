// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "Clarity",
    dependencies: [
        // Add your own dependencies here:
        .package(url: "https://github.com/pedrocid/ArxivSwift", branch: "main"),
        // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
    ]
)
