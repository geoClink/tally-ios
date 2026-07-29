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
        generate(sessions: sessions, from: startDate(for: range), to: nil, client: client)
    }

    static func generate(sessions: [SessionModel], from startDate: Date?, to endDate: Date?, client: String? = nil) -> String {
        var filtered = sessions
        if let start = startDate {
            filtered = filtered.filter { $0.startTime >= start }
        }
        if let end = endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: end)) ?? end
            filtered = filtered.filter { $0.startTime < endOfDay }
        }
        if let client {
            filtered = filtered.filter { $0.client == client }
        }

        var csv = "Date,Client,Hours,Minutes,Billable,Task Note\n"
        for session in filtered {
            let date = session.date ?? ""
            let client = session.client.replacingOccurrences(of: ",", with: ";")
            let hours = String(format: "%.2f", session.hours)
            let minutes = Int(session.hours * 60)
            let billable = session.isBillable ? "Yes" : "No"
            let note = session.taskNote?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(date),\(client),\(hours),\(minutes),\(billable),\(note)\n"
        }
        return csv
    }

    static func filter(sessions: [SessionModel], range: ExportRange) -> [SessionModel] {
        guard let start = startDate(for: range) else { return sessions }
        return sessions.filter { $0.startTime >= start }
    }

    static func save(csv: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try? csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private static func startDate(for range: ExportRange) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        switch range {
        case .thisWeek:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .thisMonth:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .allTime:
            return nil
        }
    }
}
