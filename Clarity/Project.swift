import ProjectDescription

let project = Project(
    name: "Clarity",
    targets: [
        .target(
            name: "Clarity",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Clarity",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Clarity/Sources/**"],
            resources: ["Clarity/Resources/**"],
            dependencies: [
                .target(name: "ArxivKit")
            ]
        ),
        .target(
            name: "ArxivKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.ArxivKit",
            infoPlist: .default,
            sources: ["ArxivKit/Sources/**"],
            resources: [],
            dependencies: [
                .external(name: "ArxivSwift")
            ]
        ),
        .target(
            name: "ClarityTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.ClarityTests",
            infoPlist: .default,
            sources: ["Clarity/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Clarity")]
        ),
        .target(
            name: "ArxivKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.ArxivKitTests",
            infoPlist: .default,
            sources: ["ArxivKit/Tests/**"],
            resources: [],
            dependencies: [.target(name: "ArxivKit")]
        ),
    ]
)
