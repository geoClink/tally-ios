//
//  ContentView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Supabase

private enum Tab: Hashable {
    case timer, reports, activity, team, account
}

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isAuthenticated = false
    @State private var isLoading = true
    @State private var errorHandler = ErrorHandler.shared
    @State private var selectedTab: Tab = .timer

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else if !isAuthenticated {
                AuthView()
            } else if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(selection: $selectedTab) {
                        Label("Timer", systemImage: "timer").tag(Tab.timer)
                        Label("Reports", systemImage: "chart.bar.fill").tag(Tab.reports)
                        Label("Activity", systemImage: "calendar").tag(Tab.activity)
                        Label("Team", systemImage: "person.3.fill").tag(Tab.team)
                        Label("Account", systemImage: "person.circle").tag(Tab.account)
                    }
                    .navigationTitle("Tally")
                } detail: {
                    switch selectedTab {
                    case .timer:    HomeView()
                    case .reports:  ReportsView()
                    case .activity: CalendarView()
                    case .team:     TeamView()
                    case .account:  AccountView()
                    }
                }
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
