//
//  MacContentView.swift
//  Tally Mac
//

import SwiftUI
import Supabase

extension Notification.Name {
    static let supabaseAuthStateChanged = Notification.Name("supabaseAuthStateChanged")
}

private enum Tab: Hashable {
    case timer, reports, activity, team, account
}

struct MacContentView: View {
    @State private var isAuthenticated = false
    @State private var isLoading = true
    @State private var selectedTab: Tab = .timer
    @State private var errorHandler = ErrorHandler.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !isAuthenticated {
                MacAuthView()
            } else {
                NavigationSplitView {
                    List(selection: Binding<Tab?>(
                        get: { selectedTab },
                        set: { selectedTab = $0 ?? .timer }
                    )) {
                        Label("Timer", systemImage: "timer").tag(Tab.timer)
                        Label("Reports", systemImage: "chart.bar.fill").tag(Tab.reports)
                        Label("Activity", systemImage: "calendar").tag(Tab.activity)
                        Label("Team", systemImage: "person.3.fill").tag(Tab.team)
                        Label("Account", systemImage: "person.circle").tag(Tab.account)
                    }
                    .navigationTitle("Tally")
                    .listStyle(.sidebar)
                } detail: {
                    switch selectedTab {
                    case .timer:    HomeView()
                    case .reports:  ReportsView()
                    case .activity: CalendarView()
                    case .team:     TeamView()
                    case .account:  AccountView()
                    }
                }
            }
        }
        .alert("Something went wrong", isPresented: $errorHandler.showError) {
            Button("OK", role: .cancel) { errorHandler.currentError = nil }
        } message: {
            Text(errorHandler.currentError ?? "An unknown error occurred")
        }
        .task {
            await checkAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseAuthStateChanged)) { _ in
            Task { await checkAuth() }
        }
    }

    private func checkAuth() async {
        do {
            _ = try await supabase.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
        if isAuthenticated {
            Task { await PurchaseManager.shared.refresh() }
        }
    }
}
