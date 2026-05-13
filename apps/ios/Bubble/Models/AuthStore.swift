import Foundation
import Observation
import Supabase

@Observable
final class AuthStore {
    var isLoggedIn: Bool = false
    var userEmail: String = ""

    func login(email: String) {
        isLoggedIn = true
        userEmail = email
    }

    func logout() async {
        try? await supabaseClient.auth.signOut()
        isLoggedIn = false
        userEmail = ""
    }

    func listenForAuthChanges() async {
        for await state in supabaseClient.auth.authStateChanges {
            if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                isLoggedIn = state.session != nil
                userEmail = state.session?.user.email ?? ""
            }
        }
    }
}
