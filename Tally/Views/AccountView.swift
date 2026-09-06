//
//  AccountView.swift
//  Tally
//

import SwiftUI
import StoreKit
import Supabase
import UserNotifications

struct AccountView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var userEmail: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var stripeConnected = false
    @State private var stripeConnecting = false
    @State private var showDisconnectConfirm = false
    @State private var showSupportSheet = false
    @State private var roundingRule: RoundingRule = .current
    @State private var showRoundingInfo = false
    @State private var currencyCode: String = CurrencyPreference.current
    @State private var weekStartDay: WeekStartDay = WeekStartDay.current
    @State private var showContactEmailSheet = false
    @AppStorage(NotificationManager.dailyReminderKey) private var dailyReminderEnabled = false
    @AppStorage(NotificationManager.weeklySummaryKey) private var weeklySummaryEnabled = false
    private let purchases = PurchaseManager.shared
    #if os(iOS)
    @State private var pushAuthStatus: UNAuthorizationStatus = .notDetermined
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                // Background circles
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.20))
                            .frame(width: geo.size.width * 0.85)
                            .blur(radius: 90)
                            .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.08)

                        Circle()
                            .fill(Color.indigo.opacity(0.13))
                            .frame(width: geo.size.width * 0.7)
                            .blur(radius: 75)
                            .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.55)
                    }
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Profile card
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                Text(avatarLetter)
                                    .font(.title2.bold())
                                    .foregroundStyle(.blue)
                            }
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(userEmail.isEmpty ? "Loading..." : userEmail)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(userEmail.isEmpty ? .secondary : .primary)
                                tierBadge
                            }
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(userEmail.isEmpty ? "Account loading" : "\(userEmail), \(tierLabel) plan")

                        // Free trial upsell
                        if purchases.currentTier == .free,
                           purchases.businessIntroOffer?.paymentMode == .freeTrial {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Try Business Free")
                                            .font(.headline)
                                        Text("7 days free, then \(purchases.businessProduct?.displayPrice ?? "$4.99")/month")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(.purple)
                                        .accessibilityHidden(true)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Stripe invoice payments", systemImage: "checkmark")
                                    Label("Team workspaces", systemImage: "checkmark")
                                    Label("All Pro features included", systemImage: "checkmark")
                                }
                                .font(.subheadline)

                                Button { showPaywall = true } label: {
                                    Text("Start Free Trial")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(.purple, in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Start free trial for Tally Business")
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.purple.opacity(0.08)))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                        }

                        // Subscription section
                        VStack(spacing: 0) {
                            sectionHeader("Subscription")
                            VStack(spacing: 0) {
                                accountRow(icon: "crown.fill", iconColor: .blue, label: "Current Plan", trailing: tierLabel)
                                Divider().padding(.leading, 52)
                                Button { showPaywall = true } label: {
                                    accountRow(
                                        icon: "arrow.up.circle.fill",
                                        iconColor: .blue,
                                        label: purchases.currentTier == .business ? "View Plans" : "Upgrade Plan",
                                        trailing: nil,
                                        isAction: true
                                    )
                                }
                                .buttonStyle(.plain)
                                if purchases.currentTier == .business,
                                   let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    Divider().padding(.leading, 52)
                                    Link(destination: url) {
                                        accountRow(icon: "gearshape.fill", iconColor: .secondary, label: "Manage Subscription", trailing: nil, isAction: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                                if purchases.currentTier == .business {
                                    Divider().padding(.leading, 52)
                                    Button {
                                        if stripeConnected {
                                            showDisconnectConfirm = true
                                        } else {
                                            Task { await connectStripe() }
                                        }
                                    } label: {
                                        accountRow(
                                            icon: stripeConnected ? "checkmark.circle.fill" : "creditcard.fill",
                                            iconColor: stripeConnected ? .green : .blue,
                                            label: stripeConnected ? "Stripe Connected" : (stripeConnecting ? "Connecting…" : "Connect Stripe"),
                                            trailing: nil,
                                            isAction: true
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(stripeConnecting)
                                    .confirmationDialog("Disconnect Stripe?", isPresented: $showDisconnectConfirm, titleVisibility: .visible) {
                                        Button("Disconnect", role: .destructive) {
                                            Task { await disconnectStripe() }
                                        }
                                    } message: {
                                        Text("You can reconnect at any time.")
                                    }
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        }

                        // Preferences section
                        VStack(spacing: 0) {
                            sectionHeader("Preferences")
                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    Button {
                                        showRoundingInfo = true
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Learn about time rounding")
                                    Text("Time Rounding")
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Picker("Time Rounding", selection: $roundingRule) {
                                        ForEach(RoundingRule.allCases, id: \.self) { rule in
                                            Text(rule.label).tag(rule)
                                        }
                                    }
                                    .labelsHidden()
                                    .tint(.secondary)
                                    .onChange(of: roundingRule) { _, newRule in
                                        RoundingRule.save(newRule)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                Divider().padding(.leading, 62)

                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.15))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "dollarsign.circle")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.green)
                                    }
                                    Text("Currency")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Picker("Currency", selection: $currencyCode) {
                                        ForEach(CurrencyPreference.supported, id: \.code) { item in
                                            Text(item.code).tag(item.code)
                                        }
                                    }
                                    .labelsHidden()
                                    .tint(.secondary)
                                    .onChange(of: currencyCode) { _, newCode in
                                        Task { await tallyStore.saveCurrency(newCode) }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                Divider().padding(.leading, 62)

                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.indigo.opacity(0.15))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "calendar")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.indigo)
                                    }
                                    Text("Week Starts On")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Picker("Week Starts On", selection: $weekStartDay) {
                                        ForEach(WeekStartDay.allCases, id: \.self) { day in
                                            Text(day.label).tag(day)
                                        }
                                    }
                                    .labelsHidden()
                                    .tint(.secondary)
                                    .onChange(of: weekStartDay) { _, newDay in
                                        WeekStartDay.save(newDay)
                                        tallyStore.weekStartDay = newDay
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                Divider().padding(.leading, 62)

                                Button { showContactEmailSheet = true } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "envelope.fill")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(.blue)
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Contact Email")
                                                .foregroundStyle(.primary)
                                            Text(tallyStore.contactEmail.flatMap { $0 == "dismissed" ? nil : $0 } ?? "Not set")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))

                            VStack(spacing: 0) {
                                #if os(iOS)
                                Button {
                                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.teal.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "bell.badge.fill")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(.teal)
                                        }
                                        .accessibilityHidden(true)
                                        Text("Push Notifications")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(pushStatusLabel)
                                            .font(.subheadline)
                                            .foregroundStyle(pushStatusColor)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 62)
                                #endif

                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.purple.opacity(0.15))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.purple)
                                    }
                                    Text("Daily Reminder")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Toggle("", isOn: $dailyReminderEnabled)
                                        .labelsHidden()
                                        .onChange(of: dailyReminderEnabled) { _, enabled in
                                            NotificationManager.shared.scheduleDailyReminder(enabled: enabled)
                                        }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                Divider().padding(.leading, 62)

                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.15))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.orange)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Weekly Summary")
                                            .foregroundStyle(.primary)
                                        Text("Fridays at 6 pm")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $weeklySummaryEnabled)
                                        .labelsHidden()
                                        .onChange(of: weeklySummaryEnabled) { _, enabled in
                                            NotificationManager.shared.scheduleWeeklySummary(weeklyHours: tallyStore.weeklyHours, enabled: enabled)
                                        }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                            .padding(.top, 12)

                            .alert("Time Rounding", isPresented: $showRoundingInfo) {
                                Button("Got it", role: .cancel) {}
                            } message: {
                                Text("When you stop the timer, Tally will suggest rounding the session to the nearest interval you choose.\n\nUseful for billing clients in standard increments — most freelancers bill in 15-minute blocks.")
                            }
                        }

                        // Support section
                        VStack(spacing: 0) {
                            sectionHeader("Support")
                            VStack(spacing: 0) {
                                if let reviewURL = URL(string: "itms-apps://itunes.apple.com/app/id6775275483?action=write-review") {
                                    Link(destination: reviewURL) {
                                        accountRow(icon: "star.fill", iconColor: .yellow, label: "Rate Tally", trailing: nil, isAction: true)
                                    }
                                    .buttonStyle(.plain)
                                    Divider().padding(.leading, 52)
                                }
                                Button { showSupportSheet = true } label: {
                                    accountRow(icon: "exclamationmark.bubble", iconColor: .blue, label: "Report a Problem", trailing: nil, isAction: true)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        }

                        // Danger zone
                        VStack(spacing: 0) {
                            VStack(spacing: 0) {
                                Button(role: .destructive) {
                                    Task {
                                        try? await supabase.auth.signOut()
                                        NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
                                    }
                                } label: {
                                    accountRow(icon: "rectangle.portrait.and.arrow.right", iconColor: .red, label: "Sign Out", trailing: nil, isDestructive: true)
                                }
                                .buttonStyle(.plain)

                                Divider().padding(.leading, 52)

                                Button(role: .destructive) {
                                    showDeleteConfirmation = true
                                } label: {
                                    accountRow(icon: "trash", iconColor: .red, label: "Delete Account", trailing: nil, isDestructive: true)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        }

                        // App version — taps open App Store
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let url = URL(string: "itms-apps://itunes.apple.com/app/id6775275483") {
                            Link(destination: url) {
                                Text("Tally v\(version)  ↗")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Account")
            .task { await loadEmail() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSupportSheet) { SupportSheet(userEmail: userEmail) }
            .sheet(isPresented: $showContactEmailSheet) {
                ContactEmailSheet(
                    current: tallyStore.contactEmail.flatMap { $0 == "dismissed" ? nil : $0 } ?? "",
                    onSave: { email in Task { await tallyStore.saveContactEmail(email) } }
                )
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await tallyStore.deleteAccount()
                            NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
                        } catch {
                            ErrorHandler.shared.handle(error, context: "Deleting account")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func accountRow(
        icon: String,
        iconColor: Color,
        label: String,
        trailing: String?,
        isAction: Bool = false,
        isDestructive: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            Text(label)
                .foregroundStyle(isDestructive ? .red : .primary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else if isAction && !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.bottom, 6)
    }

    private var avatarLetter: String {
        userEmail.first.map(String.init)?.uppercased() ?? "?"
    }

    private var tierLabel: String {
        switch purchases.currentTier {
        case .free:     return "Free"
        case .pro:      return "Pro"
        case .business: return "Business"
        }
    }

    private var tierBadge: some View {
        Text(tierLabel)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(tierColor.opacity(0.15))
            .foregroundStyle(tierColor)
            .clipShape(Capsule())
    }

    private var tierColor: Color {
        switch purchases.currentTier {
        case .free:     return .secondary
        case .pro:      return .blue
        case .business: return .purple
        }
    }

    private func loadEmail() async {
        userEmail = (try? await supabase.auth.user())?.email ?? ""
        await checkStripeStatus()
        #if os(iOS)
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        pushAuthStatus = settings.authorizationStatus
        #endif
    }

    #if os(iOS)
    private var pushStatusLabel: String {
        switch pushAuthStatus {
        case .authorized, .provisional, .ephemeral: return "On"
        case .denied: return "Off"
        default: return "Set Up"
        }
    }

    private var pushStatusColor: Color {
        switch pushAuthStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .secondary
        }
    }
    #endif

    private func checkStripeStatus() async {
        struct ConnectRow: Decodable { let onboarded: Bool }
        let rows: [ConnectRow]? = try? await supabase
            .from("stripe_connect_accounts")
            .select("onboarded")
            .eq("user_id", value: supabase.auth.currentUser?.id.uuidString ?? "")
            .limit(1)
            .execute()
            .value
        stripeConnected = rows?.first?.onboarded ?? false
    }

    private func connectStripe() async {
        stripeConnecting = true
        let returnURL = "https://tally-web-nu.vercel.app/billing?stripe_connected=true"
        guard let session = try? await supabase.auth.session,
              let url = URL(string: "https://fcmfuxoblbtxigknwhpz.supabase.co/functions/v1/create-connect-account") else {
            stripeConnecting = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["return_url": returnURL])
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["url"] as? String,
              let onboardingURL = URL(string: urlString) else {
            stripeConnecting = false
            return
        }
        stripeConnecting = false
        #if os(iOS)
        await UIApplication.shared.open(onboardingURL)
        #else
        NSWorkspace.shared.open(onboardingURL)
        #endif
    }

    private func disconnectStripe() async {
        guard let session = try? await supabase.auth.session,
              let url = URL(string: "https://fcmfuxoblbtxigknwhpz.supabase.co/functions/v1/create-connect-account") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["action": "disconnect"])
        _ = try? await URLSession.shared.data(for: request)
        stripeConnected = false
    }
}
