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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let store: StoreOf<AppFeature>
    let modelContainer: ModelContainer
    let notificationService: NotificationService

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
        let wishlistRepo = WishlistRepository(supabase: supabase)
        let authRepo = AuthRepository(supabase: supabase, anonKey: Secrets.supabaseAnonKey)
        let userRepo = UserRepository(supabase: supabase)
        let partnerRepo = PartnerRepository(supabase: supabase)
        let partnerConnectionRepo = PartnerConnectionRepository(supabase: supabase)
        let anniversaryRepo = AnniversaryRepository(supabase: supabase)
        let courseRepo = CourseRepository(supabase: supabase, modelContext: modelContext)
        let placeRepo = PlaceRepository(provider: kakaoProvider)
        let aiService = GPTAIService(provider: gptProvider)
        let weatherService = OpenWeatherService(apiKey: Secrets.openWeatherKey)
        let generateUseCase = GenerateCourseUseCase(aiService: aiService, placeRepository: placeRepo, weatherService: weatherService)
        let saveUseCase = SaveCourseUseCase(courseRepository: courseRepo)
        let fetchCoursesUseCase = FetchRecentCoursesUseCase(courseRepository: courseRepo)
        let fetchEffectivePartnerUseCase = FetchEffectivePartnerUseCase(partnerConnectionRepository: partnerConnectionRepo, partnerRepository: partnerRepo)
        let notificationSvc = NotificationService()
        self.notificationService = notificationSvc

        self.store = Store(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.authRepository = authRepo
            $0.userRepository = userRepo
            $0.partnerRepository = partnerRepo
            $0.partnerConnectionRepository = partnerConnectionRepo
            $0.anniversaryRepository = anniversaryRepo
            $0.notificationService = notificationSvc
            $0.courseRepository = courseRepo
            $0.wishlistRepository = wishlistRepo
            $0.placeRepository = placeRepo
            $0.generateCourseUseCase = generateUseCase
            $0.saveCourseUseCase = saveUseCase
            $0.fetchRecentCoursesUseCase = fetchCoursesUseCase
            $0.fetchEffectivePartnerUseCase = fetchEffectivePartnerUseCase
            $0.weatherService = weatherService
            $0.currentUserId = { supabase.auth.currentUser?.id ?? UUID() }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .modelContainer(modelContainer)
                .onAppear {
                    appDelegate.onFCMToken = { token in
                        store.send(.fcmTokenReceived(token))
                    }
                    store.send(.onAppear)
                    _Concurrency.Task { await notificationService.requestPermission() }
                }
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
