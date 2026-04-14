// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .staticFramework,
        "Moya": .staticFramework,
        "Supabase": .staticFramework,
    ]
)
#endif

let package = Package(
    name: "ForP",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.15.0"
        ),
        .package(
            url: "https://github.com/Moya/Moya",
            from: "15.0.0"
        ),
        .package(
            url: "https://github.com/supabase-community/supabase-swift",
            from: "2.0.0"
        ),
    ]
)
