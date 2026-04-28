import Foundation

public struct FetchEffectivePartnerUseCase {
    private let partnerConnectionRepository: any PartnerConnectionRepositoryProtocol
    private let partnerRepository: any PartnerRepositoryProtocol

    public init(
        partnerConnectionRepository: any PartnerConnectionRepositoryProtocol,
        partnerRepository: any PartnerRepositoryProtocol
    ) {
        self.partnerConnectionRepository = partnerConnectionRepository
        self.partnerRepository = partnerRepository
    }

    public func execute(userId: UUID) async throws -> Partner? {
        if let conn = try await partnerConnectionRepository.fetchConnection(userId: userId) {
            let connectedUser = try await partnerConnectionRepository.fetchUser(id: conn.partnerId(myUserId: userId))
            let localPartner = try? await partnerRepository.fetchPartner(for: userId)
            return Partner(
                userId: connectedUser.id,
                nickname: connectedUser.nickname,
                preferredCategories: connectedUser.preferredCategories,
                dislikedCategories: connectedUser.dislikedCategories,
                preferredThemes: connectedUser.preferredThemes,
                notes: localPartner?.notes ?? "",
                foodBlacklist: connectedUser.foodBlacklist
            )
        }
        return try await partnerRepository.fetchPartner(for: userId)
    }
}
