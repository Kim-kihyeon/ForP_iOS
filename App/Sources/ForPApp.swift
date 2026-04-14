import SwiftUI
import ComposableArchitecture
import Features
import Data
import Domain
import CoreNetwork
import Moya
import Supabase
import SwiftData
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct ForPApp: App {
    let store: StoreOf<AppFeature>
    let modelContainer: ModelContainer

    init() {
        KakaoSDK.initSDK(appKey: Secrets.kakaoAppKey)

        let container = try! LocalStoreContainer.make()
        self.modelContainer = container

        let supabaseURL = URL(string: Secrets.supabaseURL)
            ?? URL(string: "https://placeholder.supabase.co")!
        let supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey,
            options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
        )

        let gptProvider = MoyaProviderFactory.make(
            GPTTarget.self,
            plugins: [AuthPlugin { Secrets.openAIKey }]
        )
        let kakaoProvider = MoyaProviderFactory.make(
            KakaoTarget.self,
            plugins: [AuthPlugin(prefix: "KakaoAK") { Secrets.kakaoRestKey }]
        )

        let modelContext = ModelContext(container)
        let authRepo = AuthRepository(supabase: supabase)
        let userRepo = UserRepository(supabase: supabase)
        let partnerRepo = PartnerRepository(supabase: supabase)
        let courseRepo = CourseRepository(supabase: supabase, modelContext: modelContext)
        let placeRepo = PlaceRepository(provider: kakaoProvider)
        let aiService = GPTAIService(provider: gptProvider)
        let generateUseCase = GenerateCourseUseCase(aiService: aiService, placeRepository: placeRepo)
        let saveUseCase = SaveCourseUseCase(courseRepository: courseRepo)
        let fetchCoursesUseCase = FetchRecentCoursesUseCase(courseRepository: courseRepo)

        self.store = Store(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.authRepository = authRepo
            $0.userRepository = userRepo
            $0.partnerRepository = partnerRepo
            $0.courseRepository = courseRepo
            $0.placeRepository = placeRepo
            $0.generateCourseUseCase = generateUseCase
            $0.saveCourseUseCase = saveUseCase
            $0.fetchRecentCoursesUseCase = fetchCoursesUseCase
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
