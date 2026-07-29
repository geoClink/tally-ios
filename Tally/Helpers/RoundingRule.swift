//
//  RoundingRule.swift
//  Tally
//

import Foundation

enum RoundingRule: Int, CaseIterable {
    case none        = 0
    case sixMin      = 6
    case fifteenMin  = 15
    case thirtyMin   = 30
    case oneHour     = 60

    var label: String {
        switch self {
        case .none:       return "No rounding"
        case .sixMin:     return "6 minutes"
        case .fifteenMin: return "15 minutes"
        case .thirtyMin:  return "30 minutes"
        case .oneHour:    return "1 hour"
        }
    }

    static var current: RoundingRule {
        guard UserDefaults.standard.object(forKey: "roundingRuleMinutes") != nil else {
            return .fifteenMin
        }
        let raw = UserDefaults.standard.integer(forKey: "roundingRuleMinutes")
        return RoundingRule(rawValue: raw) ?? .fifteenMin
    }

    static func save(_ rule: RoundingRule) {
        UserDefaults.standard.set(rule.rawValue, forKey: "roundingRuleMinutes")
    }

    func apply(to hours: Double) -> Double {
        guard self != .none, rawValue > 0 else { return hours }
        let intervalHours = Double(rawValue) / 60.0
        return (hours / intervalHours).rounded() * intervalHours
    }
}
