import Foundation

enum Secrets {
    static let kakaoAppKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String ?? ""
    static let kakaoRestKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_KEY") as? String ?? ""
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    static let openAIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
}
