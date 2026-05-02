import ProjectDescription

let project = Project(
    name: "CoreNetwork",
    targets: [
        .target(
            name: "CoreNetwork",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.forp.core.network",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Moya"),
            ]
        ),
    ]
)
