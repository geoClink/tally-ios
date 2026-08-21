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
        case .none:       return "Off"
        case .sixMin:     return "6 min"
        case .fifteenMin: return "15 min"
        case .thirtyMin:  return "30 min"
        case .oneHour:    return "1 hr"
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
