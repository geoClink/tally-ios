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
    var budgetHours: Double?
    var billingStartDay: Int?
    var clientEmail: String?

    enum CodingKeys: String, CodingKey {
        case id
        case client
        case hourlyRate = "hourly_rate"
        case budgetHours = "budget_hours"
        case billingStartDay = "billing_start_day"
        case clientEmail = "client_email"
    }
}

struct ClientRateInsert: Codable {
    let userId: String
    let client: String
    let hourlyRate: Double
    let budgetHours: Double?
    let billingStartDay: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case client
        case hourlyRate = "hourly_rate"
        case budgetHours = "budget_hours"
        case billingStartDay = "billing_start_day"
    }
}
