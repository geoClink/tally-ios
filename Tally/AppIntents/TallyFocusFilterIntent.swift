//
//  TallyFocusFilterIntent.swift
//  Tally
//

import AppIntents


struct TallyFocusFilterIntent: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Select Default Client"
    static var description: IntentDescription? =
        "Pre-select a client in Tally when this Focus mode is active."

    @Parameter(title: "Client", description: "The client Tally will default to during this Focus.")
    var client: String?

    var displayRepresentation: DisplayRepresentation {
        if let client {
            return DisplayRepresentation(title: "Tally - \(client)")
        }
        return DisplayRepresentation(title: "Tally")
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}
