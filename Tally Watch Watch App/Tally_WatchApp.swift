//
//  Tally_WatchApp.swift
//  Tally Watch Watch App
//

import SwiftUI

@main
struct Tally_Watch_Watch_AppApp: App {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
