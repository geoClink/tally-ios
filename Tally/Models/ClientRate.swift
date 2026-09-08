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
    var billingCycle: String?      // "monthly" | "weekly"
    var billingStartDay: Int?      // day of month (monthly)
    var billingWeekday: Int?       // 0=Sun … 6=Sat (weekly)
    var clientEmail: String?

    enum CodingKeys: String, CodingKey {
        case id
        case client
        case hourlyRate = "hourly_rate"
        case budgetHours = "budget_hours"
        case billingCycle = "billing_cycle"
        case billingStartDay = "billing_start_day"
        case billingWeekday = "billing_weekday"
        case clientEmail = "client_email"
    }
}

struct ClientRateInsert: Codable {
    let userId: String
    let client: String
    let hourlyRate: Double
    let budgetHours: Double?
    let billingCycle: String?
    let billingStartDay: Int?
    let billingWeekday: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case client
        case hourlyRate = "hourly_rate"
        case budgetHours = "budget_hours"
        case billingCycle = "billing_cycle"
        case billingStartDay = "billing_start_day"
        case billingWeekday = "billing_weekday"
    }
}
