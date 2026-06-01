//
//  TallyWidgetsControl.swift
//  TallyWidgets
//

import AppIntents
import SwiftUI
import WidgetKit

struct OpenTallyIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Tally"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct TallyWidgetsControl: ControlWidget {
    static let kind = "name.GeorgeClinkscales.Tally.TimerControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTallyIntent()) {
                Label("Timer", systemImage: "timer")
            }
        }
        .displayName("Tally Timer")
        .description("Open Tally to start or stop your timer.")
    }
}
