import SwiftUI
import ComposableArchitecture
import Features
import Data
import Domain
import Moya
import Supabase
import SwiftData

@main
struct ForPApp: App {
    let store: StoreOf<AppFeature>
    let modelContainer: ModelContainer

    init() {
        let container = try! LocalStoreContainer.make()
        self.modelContainer = container

        let supabase = SupabaseClient(
            supabaseURL: URL(string: "https://your-project.supabase.co")!,
            supabaseKey: "your-anon-key"
        )

        let authPlugin = AuthPlugin { nil } // TODO: 토큰 제공 로직 연결
        let gptProvider = MoyaProviderFactory.make(GPTTarget.self, plugins: [authPlugin])
        let kakaoProvider = MoyaProviderFactory.make(KakaoTarget.self, plugins: [
            AuthPlugin { "your-kakao-rest-key" }
        ])

        let modelContext = ModelContext(container)
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
            $0.userRepository = userRepo
            $0.partnerRepository = partnerRepo
            $0.courseRepository = courseRepo
            $0.placeRepository = placeRepo
            $0.generateCourseUseCase = generateUseCase
            $0.saveCourseUseCase = saveUseCase
            $0.fetchRecentCoursesUseCase = fetchCoursesUseCase
            // currentUser / currentPartner / currentUserId 는 로그인 후 설정
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .modelContainer(modelContainer)
        }
    }
}
