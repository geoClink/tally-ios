//
//  TallyApp.swift
//  Tally
//

import SwiftUI
import Auth
import Supabase
import TipKit
import GoogleSignIn

@main
struct TallyApp: App {
    @State private var tallyStore = TallyStore()
    @State private var timerViewModel = TimerViewModel()

    init() {
        // Boot TipKit
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
        // Boot PurchaseManager so it starts listening for transactions immediately
        _ = PurchaseManager.shared
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "642377971570-6at6jltqmpi05ltpn4fek94m54488tqr.apps.googleusercontent.com"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tallyStore)
                .environment(timerViewModel)
                .onOpenURL { url in
                    // Google Sign-In callback
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    // Supabase auth callback
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
