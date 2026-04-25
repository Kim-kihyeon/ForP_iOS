import Foundation
import ComposableArchitecture
import Domain

// MARK: - Auth

private enum AuthRepositoryKey: DependencyKey {
    static var liveValue: any AuthRepositoryProtocol {
        fatalError("authRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - User

private enum UserRepositoryKey: DependencyKey {
    static var liveValue: any UserRepositoryProtocol {
        fatalError("userRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - PartnerConnection

private enum PartnerConnectionRepositoryKey: DependencyKey {
    static var liveValue: any PartnerConnectionRepositoryProtocol {
        fatalError("partnerConnectionRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - Partner

private enum PartnerRepositoryKey: DependencyKey {
    static var liveValue: any PartnerRepositoryProtocol {
        fatalError("partnerRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - Anniversary

private enum AnniversaryRepositoryKey: DependencyKey {
    static var liveValue: any AnniversaryRepositoryProtocol {
        fatalError("anniversaryRepository: configure via withDependencies in ForPApp")
    }
}

private enum NotificationServiceKey: DependencyKey {
    static var liveValue: any NotificationServiceProtocol {
        fatalError("notificationService: configure via withDependencies in ForPApp")
    }
}

// MARK: - Course

private enum CourseRepositoryKey: DependencyKey {
    static var liveValue: any CourseRepositoryProtocol {
        fatalError("courseRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - Wishlist

private enum WishlistRepositoryKey: DependencyKey {
    static var liveValue: any WishlistRepositoryProtocol {
        fatalError("wishlistRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - Place

private enum PlaceRepositoryKey: DependencyKey {
    static var liveValue: any PlaceRepositoryProtocol {
        fatalError("placeRepository: configure via withDependencies in ForPApp")
    }
}

// MARK: - UseCases

private enum GenerateCourseUseCaseKey: DependencyKey {
    static var liveValue: GenerateCourseUseCase {
        fatalError("generateCourseUseCase: configure via withDependencies in ForPApp")
    }
}

private enum SaveCourseUseCaseKey: DependencyKey {
    static var liveValue: SaveCourseUseCase {
        fatalError("saveCourseUseCase: configure via withDependencies in ForPApp")
    }
}

private enum FetchRecentCoursesUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentCoursesUseCase {
        fatalError("fetchRecentCoursesUseCase: configure via withDependencies in ForPApp")
    }
}

// MARK: - Weather

private enum WeatherServiceKey: DependencyKey {
    static var liveValue: any WeatherServiceProtocol {
        fatalError("weatherService: configure via withDependencies in ForPApp")
    }
}

// MARK: - Session

private enum FetchEffectivePartnerUseCaseKey: DependencyKey {
    static var liveValue: FetchEffectivePartnerUseCase {
        fatalError("fetchEffectivePartnerUseCase: configure via withDependencies in ForPApp")
    }
}

private enum CurrentUserIdKey: DependencyKey {
    static var liveValue: @Sendable () -> UUID { { UUID() } }
}

// MARK: - DependencyValues

extension DependencyValues {
    public var anniversaryRepository: any AnniversaryRepositoryProtocol {
        get { self[AnniversaryRepositoryKey.self] }
        set { self[AnniversaryRepositoryKey.self] = newValue }
    }

    public var notificationService: any NotificationServiceProtocol {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }

    public var authRepository: any AuthRepositoryProtocol {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }

    public var userRepository: any UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }

    public var partnerConnectionRepository: any PartnerConnectionRepositoryProtocol {
        get { self[PartnerConnectionRepositoryKey.self] }
        set { self[PartnerConnectionRepositoryKey.self] = newValue }
    }

    public var partnerRepository: any PartnerRepositoryProtocol {
        get { self[PartnerRepositoryKey.self] }
        set { self[PartnerRepositoryKey.self] = newValue }
    }

    public var courseRepository: any CourseRepositoryProtocol {
        get { self[CourseRepositoryKey.self] }
        set { self[CourseRepositoryKey.self] = newValue }
    }

    public var placeRepository: any PlaceRepositoryProtocol {
        get { self[PlaceRepositoryKey.self] }
        set { self[PlaceRepositoryKey.self] = newValue }
    }

    public var wishlistRepository: any WishlistRepositoryProtocol {
        get { self[WishlistRepositoryKey.self] }
        set { self[WishlistRepositoryKey.self] = newValue }
    }

    public var generateCourseUseCase: GenerateCourseUseCase {
        get { self[GenerateCourseUseCaseKey.self] }
        set { self[GenerateCourseUseCaseKey.self] = newValue }
    }

    public var saveCourseUseCase: SaveCourseUseCase {
        get { self[SaveCourseUseCaseKey.self] }
        set { self[SaveCourseUseCaseKey.self] = newValue }
    }

    public var fetchRecentCoursesUseCase: FetchRecentCoursesUseCase {
        get { self[FetchRecentCoursesUseCaseKey.self] }
        set { self[FetchRecentCoursesUseCaseKey.self] = newValue }
    }

    public var weatherService: any WeatherServiceProtocol {
        get { self[WeatherServiceKey.self] }
        set { self[WeatherServiceKey.self] = newValue }
    }

    public var fetchEffectivePartnerUseCase: FetchEffectivePartnerUseCase {
        get { self[FetchEffectivePartnerUseCaseKey.self] }
        set { self[FetchEffectivePartnerUseCaseKey.self] = newValue }
    }

    public var currentUserId: @Sendable () -> UUID {
        get { self[CurrentUserIdKey.self] }
        set { self[CurrentUserIdKey.self] = newValue }
    }
}
