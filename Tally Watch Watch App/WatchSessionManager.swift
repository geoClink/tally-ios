//
//  WatchSessionManager.swift
//  Tally Watch Watch App
//

import WatchConnectivity
import Foundation
import Combine

final class WatchSessionManager: NSObject, ObservableObject {
    @Published var clients: [String] = []
    @Published var isPro: Bool? = nil  // nil = not yet received context from phone

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        // Pick up any context that arrived while the app was closed
        let existing = WCSession.default.receivedApplicationContext
        if let saved = existing["clients"] as? [String] {
            clients = saved
        }
        if let pro = existing["isPro"] as? Bool {
            isPro = pro
        }
    }

    func sendSession(client: String, hours: Double) {
        let payload: [String: Any] = ["client": client, "hours": hours]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String: Any]) {
        let newClients = applicationContext["clients"] as? [String] ?? []
        let newIsPro = applicationContext["isPro"] as? Bool
        DispatchQueue.main.async { [weak self] in
            self?.clients = newClients
            if let pro = newIsPro { self?.isPro = pro }
        }
    }
}
