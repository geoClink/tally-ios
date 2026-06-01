//
//  WatchSessionManager.swift
//  Tally Watch Watch App
//

import WatchConnectivity
import Foundation
import Combine

final class
WatchSessionManager: NSObject, ObservableObject {
    @Published var clients: [String] = []

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
        guard let received = applicationContext["clients"] as? [String] else { return }
        DispatchQueue.main.async { [weak self] in
            self?.clients = received
        }
    }
}
