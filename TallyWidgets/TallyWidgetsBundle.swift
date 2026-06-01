//
//  TallyWidgetsBundle.swift
//  TallyWidgets
//
//  Created by George Clinkscales on 5/28/26.
//

import WidgetKit
import SwiftUI

@main
struct TallyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TallyWidgets()
        TallyWidgetsControl()
        TallyWidgetsLiveActivity()
    }
}
