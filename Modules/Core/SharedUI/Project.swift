import ProjectDescription

let project = Project(
    name: "CoreSharedUI",
    targets: [
        .target(
            name: "CoreSharedUI",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.forp.core.sharedui",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        ),
    ]
)
