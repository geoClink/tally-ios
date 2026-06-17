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
    @State private var errorHandler = ErrorHandler.shared
    
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
                        .tabItem { Label("Timer", systemImage: "timer") }
                    ReportsView()
                        .tabItem { Label("Reports", systemImage: "chart.bar.fill") }
                    CalendarView()
                        .tabItem { Label("Activity", systemImage: "calendar") }
                    TeamView()
                        .tabItem { Label("Team", systemImage: "person.3.fill") }
                    AccountView()
                        .tabItem { Label("Account", systemImage: "person.circle") }
                }
            }
        }
        .alert("Something went wrong", isPresented: $errorHandler.showError) {
            Button("OK", role: .cancel) {
                errorHandler.currentError = nil
            }
        } message: {
            Text(errorHandler.currentError ?? "An unknown error occurred")
        }
        .task {
            await checkAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseAuthStateChanged)) { _ in
            Task {
                await checkAuth()
            }
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
        if isAuthenticated {
            Task { await PurchaseManager.shared.refresh() }
        }
    }
}

extension Notification.Name {
    static let supabaseAuthStateChanged = Notification.Name("supabaseAuthStateChanged")
}
