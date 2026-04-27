import ProjectDescription

let project = Project(
    name: "ForP",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "697ACQDW6C",
            "CODE_SIGN_STYLE": "Automatic",
            "CODE_SIGN_IDENTITY": "Apple Development",
            "PROVISIONING_PROFILE_SPECIFIER": "",
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
                "NSLocationWhenInUseUsageDescription": "출발 시각 계산을 위해 현재 위치가 필요해요.",
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
                .external(name: "FirebaseMessaging"),
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic",
                "CODE_SIGN_IDENTITY": "Apple Development",
                "DEVELOPMENT_TEAM": "697ACQDW6C",
                "PROVISIONING_PROFILE_SPECIFIER": "",
                "MARKETING_VERSION": "1.0.0",
                "CURRENT_PROJECT_VERSION": "1",
                "OTHER_LDFLAGS": "-ObjC",
                "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
            ])
        ),
    ]
)
