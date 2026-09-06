//
//  PushNotificationManager.swift
//  Tally
//

#if os(iOS) || os(macOS)
import Foundation
import UserNotifications
import Supabase
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class PushNotificationManager {
    static let shared = PushNotificationManager()
    private init() {}

    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                #if os(iOS)
                UIApplication.shared.registerForRemoteNotifications()
                #elseif os(macOS)
                NSApplication.shared.registerForRemoteNotifications()
                #endif
            }
        }
    }

    func saveToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        #if os(iOS)
        let platform = "ios"
        #else
        let platform = "macos"
        #endif
        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif
        Task {
            guard let session = try? await supabase.auth.session else { return }
            let userId = session.user.id.uuidString
            try? await supabase
                .from("device_tokens")
                .upsert(
                    ["user_id": userId, "token": token, "platform": platform,
                     "environment": environment,
                     "updated_at": ISO8601DateFormatter().string(from: Date())],
                    onConflict: "user_id,token"
                )
                .execute()
        }
    }

    func removeToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            try? await supabase
                .from("device_tokens")
                .delete()
                .eq("token", value: token)
                .execute()
        }
    }
}
#endif
