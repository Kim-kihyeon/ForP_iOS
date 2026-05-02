import ProjectDescription

let project = Project(
    name: "Features",
    targets: [
        .target(
            name: "Features",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.forp.features",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "CoreSharedUI", path: "../Core/SharedUI"),
                .external(name: "ComposableArchitecture"),
            ],
            settings: .settings(base: [
                "SWIFT_STRICT_CONCURRENCY": "minimal",
            ])
        ),
    ]
)
