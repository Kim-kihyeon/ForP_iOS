import Foundation

@Observable
final class AppState {
    var user: User?
    var partner: Partner?
    var isLoggedIn: Bool = false
}
