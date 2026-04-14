import Foundation
import ComposableArchitecture
import Domain
import Data
import SwiftData

// MARK: - DependencyKey 선언 (Domain에서 사용할 키들)

private enum UserRepositoryKey: DependencyKey {
    static var liveValue: any UserRepositoryProtocol {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum PartnerRepositoryKey: DependencyKey {
    static var liveValue: any PartnerRepositoryProtocol {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum CourseRepositoryKey: DependencyKey {
    static var liveValue: any CourseRepositoryProtocol {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum PlaceRepositoryKey: DependencyKey {
    static var liveValue: any PlaceRepositoryProtocol {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum GenerateCourseUseCaseKey: DependencyKey {
    static var liveValue: GenerateCourseUseCase {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum SaveCourseUseCaseKey: DependencyKey {
    static var liveValue: SaveCourseUseCase {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum FetchRecentCoursesUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentCoursesUseCase {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum CurrentUserKey: DependencyKey {
    static var liveValue: @Sendable () -> User {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum CurrentPartnerKey: DependencyKey {
    static var liveValue: @Sendable () -> Partner? {
        fatalError("configure via withDependencies in ForPApp")
    }
}

private enum CurrentUserIdKey: DependencyKey {
    static var liveValue: @Sendable () -> UUID {
        fatalError("configure via withDependencies in ForPApp")
    }
}

// MARK: - DependencyValues extension

extension DependencyValues {
    var userRepository: any UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }

    var partnerRepository: any PartnerRepositoryProtocol {
        get { self[PartnerRepositoryKey.self] }
        set { self[PartnerRepositoryKey.self] = newValue }
    }

    var courseRepository: any CourseRepositoryProtocol {
        get { self[CourseRepositoryKey.self] }
        set { self[CourseRepositoryKey.self] = newValue }
    }

    var placeRepository: any PlaceRepositoryProtocol {
        get { self[PlaceRepositoryKey.self] }
        set { self[PlaceRepositoryKey.self] = newValue }
    }

    var generateCourseUseCase: GenerateCourseUseCase {
        get { self[GenerateCourseUseCaseKey.self] }
        set { self[GenerateCourseUseCaseKey.self] = newValue }
    }

    var saveCourseUseCase: SaveCourseUseCase {
        get { self[SaveCourseUseCaseKey.self] }
        set { self[SaveCourseUseCaseKey.self] = newValue }
    }

    var fetchRecentCoursesUseCase: FetchRecentCoursesUseCase {
        get { self[FetchRecentCoursesUseCaseKey.self] }
        set { self[FetchRecentCoursesUseCaseKey.self] = newValue }
    }

    var currentUser: @Sendable () -> User {
        get { self[CurrentUserKey.self] }
        set { self[CurrentUserKey.self] = newValue }
    }

    var currentPartner: @Sendable () -> Partner? {
        get { self[CurrentPartnerKey.self] }
        set { self[CurrentPartnerKey.self] = newValue }
    }

    var currentUserId: @Sendable () -> UUID {
        get { self[CurrentUserIdKey.self] }
        set { self[CurrentUserIdKey.self] = newValue }
    }
}
