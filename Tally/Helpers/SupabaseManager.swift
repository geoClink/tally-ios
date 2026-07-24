//
//  SupabaseManager.swift
//  Tally
//

import Foundation
import Supabase

let supabase: SupabaseClient = {
    guard let info = Bundle.main.infoDictionary else {
        fatalError("Missing Info.plist")
    }
    guard let urlString = info["SUPABASE_URL"] as? String, !urlString.isEmpty else {
        fatalError("SUPABASE_URL not set — link Config.xcconfig in Xcode project build configurations")
    }
    guard let url = URL(string: urlString) else {
        fatalError("SUPABASE_URL is not a valid URL: \(urlString)")
    }
    guard let key = info["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
        fatalError("SUPABASE_ANON_KEY not set — link Config.xcconfig in Xcode project build configurations")
    }
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: key,
        options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
    )
}()
