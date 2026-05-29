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
    var weeklyGoal: Double = 5.0
    var isLoading = false
    
    var weeklyHours: Double {
        let calendar = Calendar.current
        let now = Date()
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return sessions
            .filter { $0.startTime >= monday }
            .reduce(0) { $0 + $1.hours }
    }
    
    var recentClients: [String] {
        Array(Set(sessions.map { $0.client })).sorted()
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
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
    
    func addSession(client: String, hours: Double, taskNote: String?) async {
        guard let user = try? await supabase.auth.user() else {
            print("No user logged in")
            return
        }
        guard hours > 0.001 else {
            print("Session too short to save")
            return
        }
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
            print("Error saving session: \(error)")
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
            print("Error loading config: \(error)")
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
            print("Error saving goal: \(error)")
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
            print("Error deleting session: \(error)")
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
