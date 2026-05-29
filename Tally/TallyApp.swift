//
//  TallyApp.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Auth
import Supabase

@main
struct TallyApp: App {
    @State private var tallyStore = TallyStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tallyStore)
                .onOpenURL { url in
                    Task {
                        try? await supabase.auth.session(from: url)
                    }
                }
        }
    }
}
