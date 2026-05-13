import Foundation
import Supabase

let supabaseClient: Supabase.SupabaseClient = {
    guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
          let url = URL(string: urlString),
          let key = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String else {
        fatalError("Missing SUPABASE_URL or SUPABASE_KEY in Info.plist. Check Secrets.xcconfig.")
    }
    return Supabase.SupabaseClient(supabaseURL: url, supabaseKey: key)
}()
