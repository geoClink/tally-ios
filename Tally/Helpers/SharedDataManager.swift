//
//  SharedDataManager.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation

struct WatchSession: Codable {
    var client: String
    var startTime: Date
    var hours: Double
    var date: String
}

class SharedDataManager {
    static let shared = SharedDataManager()
    private let groupID = "group.name.GeorgeClinkscales.Tally"
    private let sessionsKey = "tally_sessions"
    private let clientsKey = "tally_clients"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }
    
    func saveSessions(_ sessions: [WatchSession]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        userDefaults?.set(data, forKey: sessionsKey)
    }
    
    func loadSessions() -> [WatchSession] {
        guard let data = userDefaults?.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([WatchSession].self, from: data)
        else { return [] }
        return sessions
    }
    
    func saveClients(_ clients: [String]) {
        userDefaults?.set(clients, forKey: clientsKey)
    }
    
    func loadClients() -> [String] {
        userDefaults?.stringArray(forKey: clientsKey) ?? []
    }
    
    func addSession(_ session: WatchSession) {
        var sessions = loadSessions()
        sessions.append(session)
        saveSessions(sessions)
    }
}
