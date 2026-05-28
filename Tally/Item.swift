//
//  Item.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
