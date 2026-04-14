import ProjectDescription

let project = Project(
    name: "Data",
    targets: [
        .target(
            name: "Data",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.forp.data",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "CoreNetwork", path: "../Core/Network"),
                .external(name: "Moya"),
                .external(name: "Supabase"),
            ]
        ),
    ]
)
