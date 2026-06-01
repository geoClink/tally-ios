//
//  ClientRate.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation

struct ClientRate: Codable, Identifiable {
    let id: UUID
    let client: String
    var hourlyRate: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case client
        case hourlyRate = "hourly_rate"
    }
}

struct ClientRateInsert: Codable {
    let userId: String
    let client: String
    let hourlyRate: Double
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case client
        case hourlyRate = "hourly_rate"
    }
}
