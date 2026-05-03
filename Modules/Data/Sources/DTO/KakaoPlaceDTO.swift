import Foundation

struct KakaoSearchResponse: Decodable {
    let meta: KakaoMeta
    let documents: [KakaoPlaceDTO]
}

struct KakaoMeta: Decodable {
    let sameName: KakaoSameName?

    enum CodingKeys: String, CodingKey {
        case sameName = "same_name"
    }
}

struct KakaoSameName: Decodable {
    let selectedRegion: String

    enum CodingKeys: String, CodingKey {
        case selectedRegion = "selected_region"
    }
}

struct KakaoPlaceDTO: Decodable {
    let id: String
    let placeName: String
    let addressName: String
    let categoryGroupCode: String
    let categoryName: String
    let x: String
    let y: String
    let placeURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case addressName = "address_name"
        case categoryGroupCode = "category_group_code"
        case categoryName = "category_name"
        case placeURL = "place_url"
        case x, y
    }
}
