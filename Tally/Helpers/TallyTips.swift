//
//  TallyTips.swift
//  Tally
//

import TipKit

struct ExportLockedTip: Tip {
    @Parameter static var isLocked: Bool = true

    var rules: [Rule] {
        #Rule(Self.$isLocked) { $0 == true }
    }

    var title: Text { Text("CSV Export is a Pro feature") }
    var message: Text? {
        Text("Upgrade to Tally Pro to export your hours as a CSV for invoicing or tax prep.")
    }
    var image: Image? { Image(systemName: "square.and.arrow.up") }
    var actions: [Action] {
        Action(id: "upgrade", title: "See Plans")
    }
}

struct InvoiceLockedTip: Tip {
    var title: Text { Text("Invoicing is a Business feature") }
    var message: Text? {
        Text("Upgrade to Tally Business to generate PDF invoices and collect Stripe payments.")
    }
    var image: Image? { Image(systemName: "doc.text") }
    var actions: [Action] {
        Action(id: "upgrade", title: "See Plans")
    }
}

struct ClientLimitTip: Tip {
    var title: Text { Text("Free plan includes 3 clients") }
    var message: Text? {
        Text("Upgrade to Tally Pro to track time for unlimited clients.")
    }
    var image: Image? { Image(systemName: "person.2") }
    var actions: [Action] {
        Action(id: "upgrade", title: "See Plans")
    }
}

struct StartTimerTip: Tip {
    var title: Text { Text("Start tracking") }
    var message: Text? {
        Text("Tap Start, pick a client, and Tally begins the clock. Stop when you're done to save the session.")
    }
    var image: Image? { Image(systemName: "timer") }
}
