//
//  PhoneSessionManager.swift
//  Tally
//

import Foundation
import Combine

#if !canImport(AppKit)
import WatchConnectivity

@MainActor
final class PhoneSessionManager: NSObject, ObservableObject {
    static let shared = PhoneSessionManager()

    var onSessionReceived: ((String, Double) async -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendClients(_ clients: [String], isPro: Bool) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isWatchAppInstalled else { return }
        try? WCSession.default.updateApplicationContext([
            "clients": clients,
            "isPro": isPro
        ])
    }
}

extension PhoneSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(userInfo)
    }

    private nonisolated func handle(_ payload: [String: Any]) {
        guard let client = payload["client"] as? String,
              let hours = payload["hours"] as? Double,
              !client.isEmpty, hours > 0 else { return }
        Task { @MainActor [weak self] in
            await self?.onSessionReceived?(client, hours)
        }
    }
}

#else

// Mac Catalyst stub -- WatchConnectivity is not available on Mac
@MainActor
final class PhoneSessionManager {
    static let shared = PhoneSessionManager()
    var onSessionReceived: ((String, Double) async -> Void)?
    private init() {}
    func sendClients(_ clients: [String], isPro: Bool) {}
}

#endif
