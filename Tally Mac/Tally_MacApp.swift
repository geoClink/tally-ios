//
//  Tally_MacApp.swift
//  Tally Mac
//

import SwiftUI

@main
struct Tally_MacApp: App {
    @State private var tallyStore = TallyStore()
    @State private var timerViewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .environment(tallyStore)
                .environment(timerViewModel)
        }
        .defaultSize(width: 900, height: 650)
    }
}
