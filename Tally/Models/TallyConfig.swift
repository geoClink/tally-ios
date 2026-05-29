//
//  TallyConfig.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation

struct TallyConfig: Codable {
    var weeklyGoal: Double
    
    init(weeklyGoal: Double = 5.0) {
        self.weeklyGoal = weeklyGoal
    }
}
