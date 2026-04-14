import ProjectDescription

let project = Project(
    name: "Domain",
    targets: [
        .target(
            name: "Domain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.forp.domain",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        ),
    ]
)
