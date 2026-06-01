//
//  CSVExporter.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation

enum ExportRange: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case allTime = "All Time"
}

struct CSVExporter {
    static func generate(sessions: [SessionModel], range: ExportRange, client: String? = nil) -> String {
        var filtered = filter(sessions: sessions, range: range)
        
        if let client = client {
            filtered = filtered.filter { $0.client == client }
        }
        
        var csv = "Date,Client,Hours,Minutes,Task Note\n"
        
        for session in filtered {
            let date = session.date ?? ""
            let client = session.client
            let hours = String(format: "%.2f", session.hours)
            let minutes = Int(session.hours * 60)
            let note = session.taskNote?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(date),\(client),\(hours),\(minutes),\(note)\n"
        }
        
        return csv
    }
    
    static func filter(sessions: [SessionModel], range: ExportRange) -> [SessionModel] {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .thisWeek:
            let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            return sessions.filter { $0.startTime >= monday }
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return sessions.filter { $0.startTime >= startOfMonth }
        case .allTime:
            return sessions
        }
    }
    
    static func save(csv: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try? csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
