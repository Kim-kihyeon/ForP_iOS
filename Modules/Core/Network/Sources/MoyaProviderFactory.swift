import Foundation
import Moya

public struct MoyaProviderFactory {
    public static func make<T: TargetType>(
        _ type: T.Type,
        plugins: [any PluginType] = []
    ) -> MoyaProvider<T> {
        MoyaProvider<T>(plugins: plugins)
    }
}
