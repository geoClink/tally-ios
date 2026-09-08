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
    var title: Text { Text("Free plan includes 5 clients") }
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

struct BillingPeriodTip: Tip {
    var title: Text { Text("Track by billing cycle") }
    var message: Text? {
        Text("Set a monthly start day or a weekly weekday. Tally will group this client's hours by billing period in Reports and pre-fill invoice date ranges automatically.")
    }
    var image: Image? { Image(systemName: "calendar.badge.clock") }
}

struct ClientSettingsTip: Tip {
    var title: Text { Text("Set rates & billing cycles") }
    var message: Text? {
        Text("Tap any client to set their hourly rate, project budget, and billing cycle. Tally uses this to pre-fill invoices and group hours in Reports.")
    }
    var image: Image? { Image(systemName: "person.text.rectangle") }
}
