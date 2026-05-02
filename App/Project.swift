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
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.kihyeonKim.ForP",
            deploymentTargets: .iOS("17.0"),
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
                "OPENWEATHER_API_KEY": "$(OPENWEATHER_API_KEY)",
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "ForP.entitlements",
            scripts: [
                .post(
                    script: """
                    set -e

                    if [[ "${PLATFORM_NAME}" == *"simulator"* ]]; then
                      echo "Skipping Firebase Crashlytics dSYM upload for simulator builds."
                      exit 0
                    fi

                    if [ -x "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
                      "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
                    elif [ -x "${SRCROOT}/../.build/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
                      "${SRCROOT}/../.build/checkouts/firebase-ios-sdk/Crashlytics/run"
                    else
                      echo "warning: Firebase Crashlytics run script not found. dSYM upload skipped."
                    fi
                    """,
                    name: "Firebase Crashlytics"
                ),
            ],
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
                .external(name: "FirebaseCrashlytics"),
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic",
                "CODE_SIGN_IDENTITY": "Apple Development",
                "DEVELOPMENT_TEAM": "697ACQDW6C",
                "PROVISIONING_PROFILE_SPECIFIER": "",
                "MARKETING_VERSION": "1.0.1",
                "CURRENT_PROJECT_VERSION": "2",
                "OTHER_LDFLAGS": "-ObjC",
                "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                "TARGETED_DEVICE_FAMILY": "1",
                "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
            ])
        ),
        .target(
            name: "ForPTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.kihyeonKim.ForPTests",
            deploymentTargets: .iOS("17.0"),
            sources: ["../ForPTests/**"],
            dependencies: [
                .target(name: "ForP"),
            ]
        ),
    ]
)
