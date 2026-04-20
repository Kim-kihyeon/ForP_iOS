import ProjectDescription

let project = Project(
    name: "ForP",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "9T6JP32M2N",
            "CODE_SIGN_STYLE": "Automatic",
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: "Secrets.xcconfig"),
            .release(name: "Release", xcconfig: "Secrets.xcconfig"),
        ]
    ),
    targets: [
        .target(
            name: "ForP",
            destinations: .iOS,
            product: .app,
            bundleId: "com.kihyeonKim.ForP",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": ""],
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLSchemes": ["kakao$(KAKAO_APP_KEY)"],
                        "CFBundleURLName": "kakao",
                    ]
                ],
                "LSApplicationQueriesSchemes": ["kakaokompassauth", "kakaoauth", "kakaolink", "kakaomap"],
                "NSFaceIDUsageDescription": "Apple 로그인에 사용됩니다.",
                "KAKAO_APP_KEY": "$(KAKAO_APP_KEY)",
                "KAKAO_REST_KEY": "$(KAKAO_REST_KEY)",
                "SUPABASE_HOST": "$(SUPABASE_HOST)",
                "SUPABASE_ANON_KEY": "$(SUPABASE_ANON_KEY)",
                "OPENAI_API_KEY": "$(OPENAI_API_KEY)",
                "OPENWEATHER_API_KEY": "$(OPENWEATHER_API_KEY)",
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "ForP.entitlements",
            dependencies: [
                .project(target: "Features", path: "../Modules/Features"),
                .project(target: "Data", path: "../Modules/Data"),
                .project(target: "Domain", path: "../Modules/Domain"),
                .project(target: "CoreNetwork", path: "../Modules/Core/Network"),
                .external(name: "ComposableArchitecture"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKUser"),
            ]
        ),
    ]
)
