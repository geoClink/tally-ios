//
//  ContentView.swift
//  Tally Watch Watch App
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedClient = ""
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var elapsedSeconds: Double = 0
    @State private var timer: Timer?
    
    let clients = ["tripsetta-android", "tripsetta-ios", "tripsetta-web", "lctway"]
    
    var body: some View {
        if isRunning {
            RunningView(
                client: selectedClient,
                elapsedSeconds: $elapsedSeconds,
                isRunning: $isRunning,
                isPaused: $isPaused,
                timer: $timer
            )
        } else {
            ClientScrollView(
                clients: clients,
                selectedClient: $selectedClient,
                isRunning: $isRunning,
                timer: $timer,
                elapsedSeconds: $elapsedSeconds
            )
        }
    }
}
