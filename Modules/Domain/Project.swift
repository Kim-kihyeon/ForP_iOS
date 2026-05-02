import ProjectDescription

let project = Project(
    name: "Domain",
    targets: [
        .target(
            name: "Domain",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.forp.domain",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        ),
    ]
)
