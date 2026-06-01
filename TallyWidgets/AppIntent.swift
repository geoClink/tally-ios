//
//  AppIntent.swift
//  TallyWidgets
//

import WidgetKit
import AppIntents

// Reload the widget timeline from a button tap or shortcut
struct ReloadWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Reload Tally Widget"

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
