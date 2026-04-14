import ProjectDescription

let project = Project(
    name: "CoreSharedUI",
    targets: [
        .target(
            name: "CoreSharedUI",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.forp.core.sharedui",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        ),
    ]
)
