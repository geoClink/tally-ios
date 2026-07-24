//
//  TallyStore.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation
import Supabase
import WidgetKit

@MainActor
@Observable
class TallyStore {
    var sessions: [SessionModel] = []

    var visibleSessions: [SessionModel] {
        PurchaseManager.shared.applyHistoryLimit(to: sessions)
    }
    var clientRates: [ClientRate] = []
    var clientGoals: [ClientGoal] = []
    var weeklyGoal: Double = 40.0
    var isLoading = false
    var currentUserId: String?
    var currentUserEmail: String?
    
    var weeklyHours: Double {
        let calendar = Calendar(identifier: .iso8601)
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

    func budgetHours(for client: String) -> Double? {
        clientRates.first { $0.client == client }?.budgetHours
    }
    
    func loadSessions() async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            let response: [SessionModel] = try await supabase
                .from("sessions")
                .select()
                .eq("user_id", value: user.id.uuidString)
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
    
    func saveClientRate(client: String, hourlyRate: Double, budgetHours: Double? = nil) async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            let rate = ClientRateInsert(
                userId: user.id.uuidString,
                client: client,
                hourlyRate: hourlyRate,
                budgetHours: budgetHours
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
    
    func addSession(client: String, hours: Double, taskNote: String?, date: Date = Date(), isManual: Bool = false) async {
        guard let user = try? await supabase.auth.user() else {
            ErrorHandler.shared.handle("No user logged in")
            return
        }
        guard hours > 0.001 else { return }
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date).prefix(10).description

        do {
            let newSession = SessionInsert(
                userId: user.id.uuidString,
                client: client,
                startTime: date,
                endTime: date,
                hours: hours,
                date: dateString,
                taskNote: taskNote,
                isManual: isManual
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

    func updateSession(_ session: SessionModel, client: String, hours: Double, date: Date, taskNote: String?) async {
        let dateString = ISO8601DateFormatter().string(from: date).prefix(10).description
        do {
            struct SessionUpdate: Encodable {
                let client: String
                let hours: Double
                let date: String
                let taskNote: String?
                enum CodingKeys: String, CodingKey {
                    case client, hours, date
                    case taskNote = "task_note"
                }
            }
            try await supabase
                .from("sessions")
                .update(SessionUpdate(client: client, hours: hours, date: dateString, taskNote: taskNote))
                .eq("id", value: session.id.uuidString)
                .execute()
            await loadSessions()
        } catch {
            ErrorHandler.shared.handle(error, context: "Updating session")
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
                let goals = config.clientGoals ?? []
                clientGoals = goals
                if !goals.isEmpty {
                    weeklyGoal = goals.reduce(0) { $0 + $1.weeklyHours }
                } else {
                    weeklyGoal = config.weeklyGoal
                }
            }
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading config")
        }
    }

    func saveGoal(_ goal: Double) async {
        guard let user = try? await supabase.auth.user() else { return }
        weeklyGoal = goal
        do {
            let config = ConfigInsert(userId: user.id.uuidString, weeklyGoal: goal, clientGoals: clientGoals)
            try await supabase
                .from("config")
                .upsert(config, onConflict: "user_id")
                .execute()
        } catch {
            ErrorHandler.shared.handle(error, context: "Saving goal")
        }
    }

    func saveClientGoal(client: String, weeklyHours: Double) async {
        guard let user = try? await supabase.auth.user() else { return }
        var updated = clientGoals.filter { $0.client != client }
        if weeklyHours > 0 {
            updated.append(ClientGoal(client: client, weeklyHours: weeklyHours))
        }
        clientGoals = updated
        do {
            let config = ConfigInsert(userId: user.id.uuidString, weeklyGoal: weeklyGoal, clientGoals: clientGoals)
            try await supabase
                .from("config")
                .upsert(config, onConflict: "user_id")
                .execute()
        } catch {
            ErrorHandler.shared.handle(error, context: "Saving client goal")
        }
    }

    func weeklyHours(for client: String) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        return sessions
            .filter { $0.client == client && $0.startTime >= monday }
            .reduce(0) { $0 + $1.hours }
    }

    func clientGoal(for client: String) -> ClientGoal? {
        clientGoals.first { $0.client == client }
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
        WidgetCenter.shared.reloadAllTimelines()
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
    var teamHoursWeekly:  [String: Double] = [:]
    var teamHoursAllTime: [String: Double] = [:]
    private var teamWeeklyTotal:  Double = 0
    private var teamAllTimeTotal: Double = 0

    private struct TeamHoursRow: Decodable {
        let memberEmail: String
        let memberUserId: String
        let totalHours: Double
        enum CodingKeys: String, CodingKey {
            case memberEmail   = "member_email"
            case memberUserId  = "member_user_id"
            case totalHours    = "total_hours"
        }
    }

    private struct TeamHoursParams: Encodable {
        let p_workspace_id: UUID
        let p_start_date: String?
    }

    func loadWorkspaces() async {
        guard let user = try? await supabase.auth.user() else { return }
        currentUserId = user.id.uuidString
        currentUserEmail = user.email
        await acceptPendingInvites(for: user)
        do {
            let all: [WorkspaceModel] = try await supabase
                .from("workspaces")
                .select()
                .execute()
                .value
            workspaces = all
            await loadWorkspaceMembers()
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

    func createWorkspace(name: String, clientName: String, weeklyGoal: Double = 0) async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            let insert = WorkspaceInsert(name: name, clientName: clientName, ownerId: user.id.uuidString, weeklyGoal: weeklyGoal)
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

            let inviterEmail = try? await supabase.auth.user().email
            struct InvitePayload: Encodable {
                let inviterEmail: String?
                let inviteeEmail: String
                let workspaceName: String
                let clientName: String
            }
            try? await supabase.functions.invoke(
                "send-invite-email",
                options: FunctionInvokeOptions(body: InvitePayload(
                    inviterEmail: inviterEmail,
                    inviteeEmail: email,
                    workspaceName: workspace.name,
                    clientName: workspace.clientName
                ))
            )
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

    func removeMember(_ member: WorkspaceMember) async {
        do {
            try await supabase
                .from("workspace_members")
                .delete()
                .eq("id", value: member.id.uuidString)
                .execute()
            await loadWorkspaceMembers()
        } catch {
            ErrorHandler.shared.handle(error, context: "Removing member")
        }
    }

    func changeMemberRole(_ member: WorkspaceMember, to role: String) async {
        do {
            try await supabase
                .from("workspace_members")
                .update(["role": role])
                .eq("id", value: member.id.uuidString)
                .execute()
            await loadWorkspaceMembers()
        } catch {
            ErrorHandler.shared.handle(error, context: "Changing member role")
        }
    }

    func loadTeamSessions(for workspace: WorkspaceModel) async {
        let isoCalendar = Calendar(identifier: .iso8601)
        let monday = isoCalendar.date(
            from: isoCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        do {
            async let weeklyFetch: [TeamHoursRow] = supabase
                .rpc("get_team_hours", params: TeamHoursParams(
                    p_workspace_id: workspace.id,
                    p_start_date: formatter.string(from: monday)
                ))
                .execute()
                .value

            async let allTimeFetch: [TeamHoursRow] = supabase
                .rpc("get_team_hours", params: TeamHoursParams(
                    p_workspace_id: workspace.id,
                    p_start_date: nil
                ))
                .execute()
                .value

            let (weekly, allTime) = try await (weeklyFetch, allTimeFetch)
            var weeklyMap:  [String: Double] = [:]
            var allTimeMap: [String: Double] = [:]
            for row in weekly  { weeklyMap[row.memberUserId]  = row.totalHours; weeklyMap[row.memberEmail]  = row.totalHours }
            for row in allTime { allTimeMap[row.memberUserId] = row.totalHours; allTimeMap[row.memberEmail] = row.totalHours }
            teamHoursWeekly  = weeklyMap
            teamHoursAllTime = allTimeMap
            teamWeeklyTotal  = weekly.reduce(0)  { $0 + $1.totalHours }
            teamAllTimeTotal = allTime.reduce(0) { $0 + $1.totalHours }
        } catch {
            ErrorHandler.shared.handle(error, context: "Loading team sessions")
        }
    }

    func teamWeeklyHours(for userId: String) -> Double {
        teamHoursWeekly[userId] ?? 0
    }

    func teamAllTimeHours(for userId: String) -> Double {
        teamHoursAllTime[userId] ?? 0
    }

    func teamTotalWeeklyHours(for workspace: WorkspaceModel) -> Double {
        teamWeeklyTotal
    }

    func teamTotalAllTimeHours(for workspace: WorkspaceModel) -> Double {
        teamAllTimeTotal
    }

    func leaveWorkspace(_ workspace: WorkspaceModel) async {
        guard let user = try? await supabase.auth.user() else { return }
        do {
            try await supabase
                .from("workspace_members")
                .delete()
                .eq("workspace_id", value: workspace.id.uuidString)
                .eq("user_id", value: user.id.uuidString)
                .execute()
            await loadWorkspaces()
        } catch {
            ErrorHandler.shared.handle(error, context: "Leaving workspace")
        }
    }

    func isOwner(of workspace: WorkspaceModel) -> Bool {
        currentUserId?.lowercased() == workspace.ownerId.lowercased()
    }

    func isAdmin(of workspace: WorkspaceModel) -> Bool {
        workspaceMembers.first {
            $0.workspaceId == workspace.id &&
            $0.userId?.lowercased() == currentUserId?.lowercased() &&
            $0.role == "admin" &&
            $0.acceptedAt != nil
        } != nil
    }

    func updateWorkspace(_ workspace: WorkspaceModel, name: String, clientName: String, weeklyGoal: Double = 0) async {
        struct WorkspaceUpdate: Encodable {
            let name: String
            let clientName: String
            let weeklyGoal: Double
            enum CodingKeys: String, CodingKey {
                case name
                case clientName = "client_name"
                case weeklyGoal = "weekly_goal"
            }
        }
        do {
            try await supabase
                .from("workspaces")
                .update(WorkspaceUpdate(name: name, clientName: clientName, weeklyGoal: weeklyGoal))
                .eq("id", value: workspace.id.uuidString)
                .execute()
            await loadWorkspaces()
        } catch {
            ErrorHandler.shared.handle(error, context: "Updating workspace")
        }
    }

    func deleteWorkspace(_ workspace: WorkspaceModel) async {
        do {
            try await supabase
                .from("workspace_members")
                .delete()
                .eq("workspace_id", value: workspace.id.uuidString)
                .execute()
            try await supabase
                .from("workspaces")
                .delete()
                .eq("id", value: workspace.id.uuidString)
                .execute()
            await loadWorkspaces()
        } catch {
            ErrorHandler.shared.handle(error, context: "Deleting workspace")
        }
    }

    func deleteAccount() async throws {
        guard let user = try? await supabase.auth.user() else { return }
        let userId = user.id.uuidString

        try await supabase.from("sessions").delete().eq("user_id", value: userId).execute()
        try await supabase.from("config").delete().eq("user_id", value: userId).execute()
        try await supabase.from("client_rates").delete().eq("user_id", value: userId).execute()
        try await supabase.from("workspace_members").delete().eq("user_id", value: userId).execute()
        try await supabase.from("subscriptions").delete().eq("user_id", value: userId).execute()

        let ownedWorkspaces: [WorkspaceModel] = try await supabase
            .from("workspaces").select().eq("owner_id", value: userId).execute().value
        for ws in ownedWorkspaces {
            try await supabase.from("workspace_members").delete().eq("workspace_id", value: ws.id.uuidString).execute()
            try await supabase.from("workspaces").delete().eq("id", value: ws.id.uuidString).execute()
        }

        try await supabase.from("profiles").delete().eq("id", value: userId).execute()
        try await supabase.rpc("delete_own_account").execute()
        try await supabase.auth.signOut()
    }

    private func acceptPendingInvites(for user: User) async {
        guard let email = user.email else { return }
        do {
            let invited: [WorkspaceMember] = try await supabase
                .from("workspace_members")
                .select()
                .eq("invited_email", value: email)
                .execute()
                .value

            for member in invited where member.acceptedAt == nil {
                try await supabase
                    .from("workspace_members")
                    .update([
                        "accepted_at": ISO8601DateFormatter().string(from: Date()),
                        "user_id": user.id.uuidString
                    ])
                    .eq("id", value: member.id.uuidString)
                    .execute()
            }
        } catch {
            // Silent — invites will be accepted on next launch
        }
    }
}

struct SessionModel: Codable, Identifiable {
    let id: UUID
    let userId: String
    let client: String
    let startTime: Date
    let endTime: Date?
    let hours: Double
    let date: String?
    let taskNote: String?
    let isManual: Bool

    enum CodingKeys: String, CodingKey {
        case id
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
    let clientGoals: [ClientGoal]?

    enum CodingKeys: String, CodingKey {
        case id
        case weeklyGoal = "weekly_goal"
        case clientGoals = "client_goals"
    }
}

struct ConfigInsert: Codable {
    let userId: String
    let weeklyGoal: Double
    let clientGoals: [ClientGoal]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case weeklyGoal = "weekly_goal"
        case clientGoals = "client_goals"
    }
}

struct ClientGoal: Codable, Identifiable, Equatable {
    var id: String { client }
    let client: String
    let weeklyHours: Double

    enum CodingKeys: String, CodingKey {
        case client
        case weeklyHours = "weekly_hours"
    }
}
