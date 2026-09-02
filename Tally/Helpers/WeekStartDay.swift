//
//  WeekStartDay.swift
//  Tally
//

import Foundation

enum WeekStartDay: Int, CaseIterable {
    case sunday   = 1
    case monday   = 2
    case saturday = 7

    var label: String {
        switch self {
        case .sunday:   return "Sunday"
        case .monday:   return "Monday"
        case .saturday: return "Saturday"
        }
    }

    static let defaultsKey = "weekStartDay"

    static var current: WeekStartDay {
        let raw = UserDefaults.standard.integer(forKey: defaultsKey)
        return WeekStartDay(rawValue: raw) ?? .monday
    }

    static func save(_ day: WeekStartDay) {
        UserDefaults.standard.set(day.rawValue, forKey: defaultsKey)
    }

    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = rawValue
        return cal
    }
}
