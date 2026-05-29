//
//  ContentView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isAuthenticated = false
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else if !isAuthenticated {
                AuthView()
            } else {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Timer", systemImage: "timer")
                        }
                    ReportsView()
                        .tabItem {
                            Label("Reports", systemImage: "chart.bar.fill")
                        }
                }
            }
        }
        .task {
            await checkAuth()
        }
    }
    
    private func checkAuth() async {
        do {
            let session = try await supabase.auth.session
            isAuthenticated = session != nil
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }
}
