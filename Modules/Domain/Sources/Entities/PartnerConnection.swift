import Foundation

public struct PartnerConnection: Identifiable, Codable, Equatable {
    public var id: UUID
    public var requesterId: UUID
    public var receiverId: UUID
    public var status: String
    public var inviteCode: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        requesterId: UUID,
        receiverId: UUID,
        status: String = "accepted",
        inviteCode: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.requesterId = requesterId
        self.receiverId = receiverId
        self.status = status
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }

    public func partnerId(myUserId: UUID) -> UUID {
        requesterId == myUserId ? receiverId : requesterId
    }

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterId = "requester_id"
        case receiverId = "receiver_id"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

public enum PartnerConnectionError: LocalizedError {
    case codeNotFound
    case cannotConnectToSelf
    case connectionFailed
    case userNotFound

    public var errorDescription: String? {
        switch self {
        case .codeNotFound: return "코드를 찾을 수 없어요. 다시 확인해주세요."
        case .cannotConnectToSelf: return "자기 자신과 연동할 수 없어요."
        case .connectionFailed: return "연동에 실패했어요. 다시 시도해주세요."
        case .userNotFound: return "사용자를 찾을 수 없어요."
        }
    }
}
