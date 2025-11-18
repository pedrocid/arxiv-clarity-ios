import ProjectDescription

let project = Project(
    name: "Clarity",
    targets: [
        .target(
            name: "Clarity",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Clarity",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSAppTransportSecurity": [
                        "NSExceptionDomains": [
                            "export.arxiv.org": [
                                "NSExceptionAllowsInsecureHTTPLoads": true,
                                "NSExceptionMinimumTLSVersion": "TLSv1.2"
                            ],
                            "arxiv.org": [
                                "NSExceptionAllowsInsecureHTTPLoads": true,
                                "NSExceptionMinimumTLSVersion": "TLSv1.2"
                            ]
                        ]
                    ]
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
            deploymentTargets: .iOS("17.0"),
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
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Clarity/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Clarity")],
            settings: .settings(
                base: [
                    "ENABLE_TESTING_SEARCH_PATHS": "YES"
                ]
            )
        ),
        .target(
            name: "ArxivKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.ArxivKitTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["ArxivKit/Tests/**"],
            resources: [],
            dependencies: [.target(name: "ArxivKit")],
            settings: .settings(
                base: [
                    "ENABLE_TESTING_SEARCH_PATHS": "YES"
                ]
            )
        ),
    ]
)
