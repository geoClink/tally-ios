//
//  Session.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation

struct Session: Codable, Identifiable {
    let id: UUID
    var client: String
    var startTime: Date
    var endTime: Date?
    var hours: Double
    var date: String
    var isManual: Bool
    
    init(id: UUID = UUID(), client: String, startTime: Date = .now) {
        self.id = id
        self.client = client
        self.startTime = startTime
        self.endTime = nil
        self.hours = 0.0
        self.date = ISO8601DateFormatter().string(from: startTime).prefix(10).description
        self.isManual = false
    }
}
