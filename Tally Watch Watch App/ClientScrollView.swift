//
//  Untitled.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ClientScrollView: View {
    let clients: [String]
    @Binding var selectedClient: String
    @Binding var isRunning: Bool
    @Binding var timer: Timer?
    @Binding var elapsedSeconds: Double
    @Binding var timerStartDate: Date
    @Binding var accumulatedSeconds: Double
    
    @State private var scrollIndex = 0
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Tally")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            TabView(selection: $scrollIndex) {
                ForEach(0..<clients.count, id: \.self) { index in
                    VStack(spacing: 12) {
                        Text(clients[index])
                            .font(.system(size: 14, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                        
                        Button {
                            selectedClient = clients[index]
                            accumulatedSeconds = 0
                            elapsedSeconds = 0
                            timerStartDate = Date()
                            isRunning = true
                            let defaults = UserDefaults.standard
                            defaults.set(true, forKey: "timerRunning")
                            defaults.set(false, forKey: "timerPaused")
                            defaults.set(clients[index], forKey: "timerClient")
                            defaults.set(0.0, forKey: "timerAccumulated")
                            defaults.set(timerStartDate.timeIntervalSince1970, forKey: "timerStartDate")
                            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                elapsedSeconds = accumulatedSeconds + Date().timeIntervalSince(timerStartDate)
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Circle().fill(Color.green))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start timer for \(clients[index])")
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .frame(maxHeight: .infinity)
        }
    }
}
