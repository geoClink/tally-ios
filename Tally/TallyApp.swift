//
//  TallyApp.swift
//  Tally
//

import SwiftUI
import Auth
import Supabase
import TipKit

@main
struct TallyApp: App {
    @State private var tallyStore = TallyStore()

    init() {
        // Boot TipKit
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
        // Boot PurchaseManager so it starts listening for transactions immediately
        _ = PurchaseManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tallyStore)
                .onOpenURL { url in
                    Task {
                        try? await supabase.auth.session(from: url)
                    }
                }
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    PhoneSessionManager.shared.onSessionReceived = { client, hours in
                        await tallyStore.addSession(client: client, hours: hours, taskNote: nil)
                    }
                }
        }
    }
}
