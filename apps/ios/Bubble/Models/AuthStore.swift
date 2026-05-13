import Foundation
import Observation

@Observable
final class AuthStore {
    var isLoggedIn: Bool = false
    var userEmail: String = ""

    func login(email: String) {
        isLoggedIn = true
        userEmail = email
    }

    func logout() async {
        await SupabaseAuthClient.shared.signOut()
        isLoggedIn = false
        userEmail = ""
    }

    func listenForAuthChanges() async {
        refreshFromStoredSession()
    }

    func refreshFromStoredSession() {
        guard let session = SupabaseAuthClient.shared.loadSession() else {
            isLoggedIn = false
            userEmail = ""
            return
        }

        isLoggedIn = true
        userEmail = session.email
    }
}
