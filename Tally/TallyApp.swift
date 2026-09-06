//
//  TallyApp.swift
//  Tally
//

import SwiftUI
import Auth
import Supabase
import TipKit
#if !os(visionOS)
import GoogleSignIn
#endif

@main
struct TallyApp: App {
    @State private var tallyStore = TallyStore()
    @State private var timerViewModel = TimerViewModel()

    init() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
        _ = PurchaseManager.shared
        #if !os(visionOS)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "642377971570-6at6jltqmpi05ltpn4fek94m54488tqr.apps.googleusercontent.com"
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tallyStore)
                .environment(timerViewModel)
                .onOpenURL { url in
                    #if !os(visionOS)
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    #endif
                    Task {
                        try? await supabase.auth.session(from: url)
                    }
                }
                .task {
                    await tallyStore.loadConfig()
                }
                .onAppear {
                    PhoneSessionManager.shared.onSessionReceived = { client, hours in
                        guard PurchaseManager.shared.hasWatchAndWidgets else { return }
                        await tallyStore.addSession(client: client, hours: hours, taskNote: nil)
                    }
                }
        }
        #if os(visionOS)
        .defaultLaunchBehavior(.presented)
        #endif

        #if os(visionOS)
        WindowGroup(id: "timer-volume") {
            TimerVolumeView()
                .environment(timerViewModel)
                .environment(tallyStore)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.3, height: 0.3, depth: 0.3, in: .meters)
        .defaultWindowPlacement { _, context in
            // Place the volume to the left of the main window
            if let mainWindow = context.windows.first(where: { $0.id != "timer-volume" }) {
                return WindowPlacement(.leading(mainWindow))
            }
            return WindowPlacement()
        }
        .defaultLaunchBehavior(.suppressed)
        #endif
    }
}
