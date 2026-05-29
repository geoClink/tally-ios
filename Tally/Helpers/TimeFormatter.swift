//
//  TimeFormatter.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct TimeFormatter {
    static func format(_ hours: Double) -> String {
        let totalSeconds = Int(hours * 3600)
        let hrs = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hrs == 0 {
            return String(format: "%02d:%02d", mins, secs)
        }
        return String(format: "%d:%02d:%02d", hrs, mins, secs)
    }
    
    static func shortFormat(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        
        if hrs == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hrs)h" }
        return "\(hrs)h \(mins)m"
    }
    
    static func accessibleFormat(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        let secs = Int(hours * 3600) % 60
        
        var parts: [String] = []
        if hrs > 0 { parts.append("\(hrs) hour\(hrs == 1 ? "" : "s")") }
        if mins > 0 { parts.append("\(mins) minute\(mins == 1 ? "" : "s")") }
        if secs > 0 && hrs == 0 { parts.append("\(secs) second\(secs == 1 ? "" : "s")") }
        
        return parts.isEmpty ? "zero seconds" : parts.joined(separator: " and ")
    }
}
