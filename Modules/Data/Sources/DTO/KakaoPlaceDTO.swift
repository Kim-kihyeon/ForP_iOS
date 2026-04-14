import Foundation

struct KakaoSearchResponse: Decodable {
    let documents: [KakaoPlaceDTO]
}

struct KakaoPlaceDTO: Decodable {
    let placeName: String
    let addressName: String
    let x: String
    let y: String

    enum CodingKeys: String, CodingKey {
        case placeName = "place_name"
        case addressName = "address_name"
        case x, y
    }
}
