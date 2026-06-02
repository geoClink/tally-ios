//
//  TallyStore.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation
import Supabase

@MainActor
@Observable
class TallyStore {
    var sessions: [SessionModel] = []

    var visibleSessions: [SessionModel] {
        PurchaseManager.shared.applyHistoryLimit(to: sessions)
    }
    var clientRates: [ClientRate] = []
    var weeklyGoal: Double = 5.0
    var isLoading = false
    
    var weeklyHours: Double {
        let calendar = Calendar.current
        let now = Date()
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        return sessions
            .filter { $0.startTime >= monday }
            .reduce(0) { $0 + $1.hours }
    }
    
    var recentClients: [String] {
        Array(Set(sessions.map { $0.client })).sorted()
    }
    
    func hourlyRate(for client: String) -> Double {
        clientRates.first { $0.client == client }?.hourlyRate ?? 0
    }
    
    func loadSessions() async {
        do {
            let response: [SessionModel] = try await supabase
                .from("sessions")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            sessions = response
            PhoneSessionManager.shared.sendClients(recentClients)
            writeWidgetSummary()
            await drainPendingQueue()
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading sessions")
        }
    }
    
    func loadClientRates() async {
        do {
            let response: [ClientRate] = try await supabase
                .from("client_rates")
                .select()
                .execute()
                .value
            clientRates = response
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading client rates")
        }
    }
    
    func saveClientRate(client: String, hourlyRate: Double) async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            let rate = ClientRateInsert(
                userId: user.id.uuidString,
                client: client,
                hourlyRate: hourlyRate
            )
            try await supabase
                .from("client_rates")
                .upsert(rate)
                .execute()
            await loadClientRates()
        } catch {
            ErrorHandler.shared.handle(error, context: "Saving client rate")
        }
    }
    
    func addSession(client: String, hours: Double, taskNote: String?) async {
        guard let user = try? await supabase.auth.user() else {
            ErrorHandler.shared.handle("No user logged in")
            return
        }
        guard hours > 0.001 else { return }
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: now).prefix(10).description
        
        do {
            let newSession = SessionInsert(
                userId: user.id.uuidString,
                client: client,
                startTime: now,
                endTime: now,
                hours: hours,
                date: dateString,
                taskNote: taskNote,
                isManual: false
            )
            try await supabase
                .from("sessions")
                .insert(newSession)
                .execute()
            await loadSessions()
            NotificationManager.shared.scheduleGoalWarning(current: weeklyHours, goal: weeklyGoal)
        } catch {
            ErrorHandler.shared.handle(error, context: "Saving session")
        }
    }
    
    func loadConfig() async {
        do {
            let response: [ConfigModel] = try await supabase
                .from("config")
                .select()
                .execute()
                .value
            if let config = response.first {
                weeklyGoal = config.weeklyGoal
            }
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading config")
        }
    }
    
    func saveGoal(_ goal: Double) async {
        weeklyGoal = goal
        do {
            let config = ConfigInsert(weeklyGoal: goal)
            try await supabase
                .from("config")
                .upsert(config)
                .execute()
        } catch {
            ErrorHandler.shared.handle(error, context: "Saving goal")
        }
    }
    
    func writeWidgetSummary() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessions.filter { $0.startTime >= today }
        let todayHours = todaySessions.reduce(0) { $0 + $1.hours }
        var byClient: [String: Double] = [:]
        for s in todaySessions { byClient[s.client, default: 0] += s.hours }
        let topClient = byClient.max(by: { $0.value < $1.value })?.key ?? ""
        AppGroupStore.writeSummary(
            todayHours: todayHours,
            weeklyHours: weeklyHours,
            weeklyGoal: weeklyGoal,
            topClient: topClient,
            recentClients: recentClients
        )
    }

    func drainPendingQueue() async {
        let queue = AppGroupStore.pendingSessionsQueue()
        guard !queue.isEmpty else { return }
        AppGroupStore.clearPendingSessionsQueue()
        for session in queue {
            await addSession(client: session.client, hours: session.hours, taskNote: nil)
        }
    }

    func deleteSessions(at offsets: IndexSet) async {
        let sessionsToDelete = offsets.map { sessions[$0] }
        do {
            for session in sessionsToDelete {
                try await supabase
                    .from("sessions")
                    .delete()
                    .eq("id", value: session.id.uuidString)
                    .execute()
            }
            await loadSessions()
        } catch {
            ErrorHandler.shared.handle(error, context: "Deleting session")
        }
    }

    // MARK: - Workspaces

    var workspaces: [WorkspaceModel] = []
    var workspaceMembers: [WorkspaceMember] = []

    func loadWorkspaces() async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            let all: [WorkspaceModel] = try await supabase
                .from("workspaces")
                .select()
                .execute()
                .value
            workspaces = all
            await loadWorkspaceMembers()
            _ = user
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading workspaces")
        }
    }

    func loadWorkspaceMembers() async {
        guard !workspaces.isEmpty else { return }
        do {
            let ids = workspaces.map { $0.id.uuidString }
            let members: [WorkspaceMember] = try await supabase
                .from("workspace_members")
                .select()
                .in("workspace_id", values: ids)
                .execute()
                .value
            workspaceMembers = members
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading workspace members")
        }
    }

    func createWorkspace(name: String) async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            let insert = WorkspaceInsert(name: name, ownerId: user.id.uuidString)
            try await supabase
                .from("workspaces")
                .insert(insert)
                .execute()
            await loadWorkspaces()
        } catch {
            ErrorHandler.shared.handle(error, context: "Creating workspace")
        }
    }

    func inviteMember(email: String, to workspace: WorkspaceModel) async {
        do {
            let insert = WorkspaceInviteInsert(
                workspaceId: workspace.id,
                invitedEmail: email,
                role: "member"
            )
            try await supabase
                .from("workspace_members")
                .insert(insert)
                .execute()
            await loadWorkspaceMembers()
        } catch {
            ErrorHandler.shared.handle(error, context: "Inviting member")
        }
    }

    func acceptInvite(memberId: UUID) async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            try await supabase
                .from("workspace_members")
                .update([
                    "accepted_at": ISO8601DateFormatter().string(from: Date()),
                    "user_id": user.id.uuidString
                ])
                .eq("id", value: memberId.uuidString)
                .execute()
            await loadWorkspaces()
        } catch {
            ErrorHandler.shared.handle(error, context: "Accepting invite")
        }
    }
}

struct SessionModel: Codable, Identifiable {
    let id: UUID
    let client: String
    let startTime: Date
    let endTime: Date?
    let hours: Double
    let date: String?
    let taskNote: String?
    let isManual: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case client
        case startTime = "start_time"
        case endTime = "end_time"
        case hours
        case date
        case taskNote = "task_note"
        case isManual = "is_manual"
    }
}

struct SessionInsert: Codable {
    let userId: String
    let client: String
    let startTime: Date
    let endTime: Date
    let hours: Double
    let date: String
    let taskNote: String?
    let isManual: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case client
        case startTime = "start_time"
        case endTime = "end_time"
        case hours
        case date
        case taskNote = "task_note"
        case isManual = "is_manual"
    }
}

struct ConfigModel: Codable {
    let id: UUID
    let weeklyGoal: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case weeklyGoal = "weekly_goal"
    }
}

struct ConfigInsert: Codable {
    let weeklyGoal: Double
    
    enum CodingKeys: String, CodingKey {
        case weeklyGoal = "weekly_goal"
    }
}
