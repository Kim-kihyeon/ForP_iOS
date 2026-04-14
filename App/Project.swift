import ProjectDescription

let project = Project(
    name: "ForP",
    targets: [
        .target(
            name: "ForP",
            destinations: .iOS,
            product: .app,
            bundleId: "com.forp.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Features", path: "../Modules/Features"),
                .project(target: "Data", path: "../Modules/Data"),
                .project(target: "Domain", path: "../Modules/Domain"),
                .external(name: "ComposableArchitecture"),
            ]
        ),
    ]
)
