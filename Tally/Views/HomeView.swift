//
//  HomeView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Supabase
import AppIntents
import StoreKit
import AudioToolbox

struct HomeView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(TimerViewModel.self) private var viewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.requestReview) private var requestReview
    @Environment(\.colorScheme) private var colorScheme

    private var accessibleOrange: Color {
        colorScheme == .dark ? .orange : Color(red: 0.65, green: 0.30, blue: 0.0)
    }

    private var accessibleRed: Color {
        colorScheme == .dark ? .red : Color(red: 0.75, green: 0.0, blue: 0.04)
    }

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    private var weeklyEarnings: Double {
        tallyStore.recentClients.reduce(0) { sum, client in
            sum + tallyStore.weeklyHours(for: client) * tallyStore.hourlyRate(for: client)
        }
    }

    private var timerFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 38
        case .medium: return 42
        case .large: return 44
        case .xLarge: return 38
        case .xxLarge: return 34
        case .xxxLarge: return 28
        case .accessibility1: return 24
        case .accessibility2: return 20
        case .accessibility3, .accessibility4, .accessibility5: return 18
        default: return 44
        }
    }

    @AppStorage("trackingStreak") private var trackingStreak = 0
    @AppStorage("lastTrackedDateInterval") private var lastTrackedDateInterval: Double = 0

    @State private var ringPulse = false
    @State private var showSavedFlash = false
    @State private var goalReachedFlash = false

    @State private var showClientPicker = false
    @State private var showManualEntry = false
    @State private var showGoalSetting = false
    @State private var showTaskNote = false
    @State private var showSatisfactionPrompt = false
    @State private var selectedClient = ""
    @State private var taskNoteText = ""
    @State private var pendingHours: Double = 0
    @State private var pendingBillable: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Decorative background circles
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.20))
                            .frame(width: geo.size.width * 0.9)
                            .blur(radius: 90)
                            .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.05)

                        Circle()
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: geo.size.width * 0.75)
                            .blur(radius: 80)
                            .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.55)
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    timerRing

                    if !tallyStore.clientGoals.isEmpty && !viewModel.isRunning {
                        clientGoalsSummary
                            .padding(.horizontal)
                            .padding(.top, 24)
                    }

                    Spacer()

                    controls
                        .padding(.horizontal)
                        .padding(.bottom, 36)
                        .animation(.spring(duration: 0.3), value: viewModel.isRunning)
                }
            }
            .navigationTitle("Tally")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button { showManualEntry = true } label: {
                            Label("Log Hours Manually", systemImage: "pencil")
                        }
                        Button { showGoalSetting = true } label: {
                            Label("Set Weekly Goal", systemImage: "target")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More options")
                }
            }
            .task {
                await applyFocusFilter()
                checkPendingIntents()
            }
            .onChange(of: viewModel.isRunning) { _, isRunning in
                ringPulse = isRunning && !viewModel.isPaused
            }
            .onChange(of: viewModel.isPaused) { _, isPaused in
                ringPulse = viewModel.isRunning && !isPaused
            }
            .onChange(of: tallyStore.weeklyHours) { oldHours, newHours in
                guard tallyStore.weeklyGoal > 0,
                      oldHours < tallyStore.weeklyGoal,
                      newHours >= tallyStore.weeklyGoal else { return }
                triggerGoalFlash()
            }
            .sheet(isPresented: $showClientPicker) {
                ClientPickerView(
                    selectedClient: $selectedClient,
                    recentClients: tallyStore.recentClients
                ) {
                    viewModel.start(client: selectedClient)
                    showClientPicker = false
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
            }
            .sheet(isPresented: $showManualEntry) { ManualEntryView() }
            .sheet(isPresented: $showGoalSetting) { GoalSettingView() }
            .alert("Enjoying Tally?", isPresented: $showSatisfactionPrompt) {
                Button("Yes, I love it!") {
                    requestReview()
                }
                Button("Could be better") {
                    // Let them report feedback instead of leaving a bad review
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Your feedback helps Tally improve. If you're happy with it, an App Store rating takes just a second.")
            }
            .sheet(isPresented: $showTaskNote) {
                TaskNoteSheet(
                    client: selectedClient,
                    hours: $pendingHours,
                    noteText: $taskNoteText,
                    isBillable: $pendingBillable,
                    onSkip: {
                        Task {
                            await tallyStore.addSession(client: selectedClient, hours: pendingHours, taskNote: nil, isBillable: pendingBillable)
                            taskNoteText = ""
                            pendingBillable = true
                            showTaskNote = false
                            maybeRequestReview()
                            try? await Task.sleep(for: .seconds(0.5))
                            withAnimation(.spring(duration: 0.3)) { showSavedFlash = true }
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation(.easeOut(duration: 0.4)) { showSavedFlash = false }
                        }
                    },
                    onSave: {
                        Task {
                            await tallyStore.addSession(client: selectedClient, hours: pendingHours, taskNote: taskNoteText.isEmpty ? nil : taskNoteText, isBillable: pendingBillable)
                            taskNoteText = ""
                            pendingBillable = true
                            showTaskNote = false
                            maybeRequestReview()
                            try? await Task.sleep(for: .seconds(0.5))
                            withAnimation(.spring(duration: 0.3)) { showSavedFlash = true }
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation(.easeOut(duration: 0.4)) { showSavedFlash = false }
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationBackground(Color(.systemBackground))
            }
        }
    }

    // MARK: - Subviews

    private var clientGoalsSummary: some View {
        VStack(spacing: 10) {
            ForEach(tallyStore.clientGoals) { goal in
                VStack(spacing: 4) {
                    HStack {
                        Text(goal.client)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(TimeFormatter.shortFormat(tallyStore.weeklyHours(for: goal.client))) / \(TimeFormatter.shortFormat(goal.weeklyHours))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressBarView(
                        value: tallyStore.weeklyHours(for: goal.client),
                        goal: goal.weeklyHours
                    )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(goal.client): \(TimeFormatter.accessibleFormat(tallyStore.weeklyHours(for: goal.client))) of \(TimeFormatter.accessibleFormat(goal.weeklyHours)) goal this week")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }

    private var timerRing: some View {
        let progress = tallyStore.weeklyGoal > 0
            ? min(1.0, tallyStore.weeklyHours / tallyStore.weeklyGoal)
            : 0.0

        return ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.07), lineWidth: 10)

            // Breathing glow when timer is running
            if viewModel.isRunning && !viewModel.isPaused {
                Circle()
                    .stroke(Color.blue.opacity(0.12), lineWidth: 18)
                    .blur(radius: 10)
                    .scaleEffect(ringPulse ? 1.05 : 0.97)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: ringPulse)
            }

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Goal reached flash — green overlay fades in then out
            Circle()
                .trim(from: 0, to: 1.0)
                .stroke(Color.green.opacity(goalReachedFlash ? 0.55 : 0), lineWidth: 10)
                .scaleEffect(goalReachedFlash ? 1.06 : 1.0)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.4), value: goalReachedFlash)

            // Timer content
            VStack(spacing: 6) {
                if viewModel.isRunning {
                    Text(viewModel.activeClient)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Current client: \(viewModel.activeClient)")
                }

                Text(viewModel.isRunning
                     ? TimeFormatter.format(viewModel.elapsedSeconds / 3600)
                     : "00:00:00")
                    .font(.system(size: timerFontSize, weight: .thin, design: .monospaced))
                    .foregroundStyle(viewModel.isRunning ? .primary : .secondary)
                    .accessibilityLabel(viewModel.isRunning
                        ? "Elapsed time: \(TimeFormatter.accessibleFormat(viewModel.elapsedSeconds / 3600))"
                        : "No active timer")
                    .accessibilityAddTraits(.updatesFrequently)

                Text(viewModel.isRunning
                     ? (viewModel.isPaused ? "Paused" : "Running")
                     : "Ready to start")
                    .font(.caption2)
                    .foregroundStyle(
                        viewModel.isRunning
                            ? (viewModel.isPaused ? accessibleOrange : Color.green)
                            : Color.secondary.opacity(0.5)
                    )

                if !viewModel.isRunning {
                    if tallyStore.todayHours > 0 {
                        Text("\(TimeFormatter.shortFormat(tallyStore.todayHours)) today")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.7))
                            .padding(.top, 2)
                            .accessibilityLabel("\(TimeFormatter.accessibleFormat(tallyStore.todayHours)) tracked today")
                    }
                    if tallyStore.weeklyHours > 0 {
                        Text("\(TimeFormatter.shortFormat(tallyStore.weeklyHours)) this week")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.4))
                            .accessibilityLabel("\(TimeFormatter.accessibleFormat(tallyStore.weeklyHours)) tracked this week")
                    }
                    if weeklyEarnings > 0 {
                        Text(weeklyEarnings.formatted(.currency(code: CurrencyPreference.current)))
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.55))
                            .accessibilityLabel("Estimated earnings this week: \(weeklyEarnings.formatted(.currency(code: CurrencyPreference.current)))")
                    }
                    if trackingStreak >= 2 {
                        Text("\(trackingStreak)-day streak")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                            .accessibilityLabel("\(trackingStreak) day tracking streak")
                    }
                }
            }
            .opacity(showSavedFlash ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: showSavedFlash)
            // Session saved flash
            if showSavedFlash {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Color.green)
                    Text("Saved")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.green)
                }
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(width: 260, height: 260)
    }

    @ViewBuilder
    private var controls: some View {
        if !viewModel.isRunning {
            VStack(spacing: 10) {
                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    AudioServicesPlaySystemSound(1113)
                    #endif
                    showClientPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                            .shadow(color: .green.opacity(0.35), radius: 16, y: 6)
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .offset(x: 3) // optical center for play icon
                    }
                }
                .accessibilityLabel("Start timer")
                .accessibilityHint("Opens client picker to begin tracking time")

                Text("Start Timer")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        } else {
            HStack(spacing: 16) {
                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    AudioServicesPlaySystemSound(1057)
                    #endif
                    viewModel.isPaused ? viewModel.resume() : viewModel.pause()
                } label: {
                    Label(viewModel.isPaused ? "Resume" : "Pause",
                          systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(viewModel.isPaused ? Color.blue : accessibleOrange)
                        )
                }
                .accessibilityLabel(viewModel.isPaused ? "Resume timer" : "Pause timer")

                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    AudioServicesPlaySystemSound(1114)
                    #endif
                    pendingHours = viewModel.stop()
                    showTaskNote = true
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(accessibleRed))
                }
                .accessibilityLabel("Stop timer")
                .accessibilityHint("Stops and saves the current session for \(viewModel.activeClient)")
            }
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private func checkPendingIntents() {
        if let client = AppGroupStore.pendingStartClient(), !viewModel.isRunning {
            AppGroupStore.clearPendingIntents()
            viewModel.start(client: client)
        } else if AppGroupStore.pendingStop(), viewModel.isRunning {
            AppGroupStore.clearPendingIntents()
            pendingHours = viewModel.stop()
            showTaskNote = true
        } else if let state = AppGroupStore.readTimerState(), !viewModel.isRunning {
            // Timer was started via Siri while app was suspended in memory — resume it.
            viewModel.start(client: state.client)
        }
    }

    private func applyFocusFilter() async {
        guard let filter = try? await TallyFocusFilterIntent.current,
              let client = filter.client, !client.isEmpty else { return }
        selectedClient = client
    }

    private func maybeRequestReview() {
        let key = "completedSessionCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        if count == 1 {
            NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleFirstReturnNudge(todayHours: tallyStore.todayHours)
        }
        if (count == 5 && trackingStreak >= 2) || (count > 5 && (count - 5) % 15 == 0 && trackingStreak >= 2) {
            // Show satisfaction gate before asking for App Store review
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showSatisfactionPrompt = true
            }
        }
        updateStreak()
    }

    private func triggerGoalFlash() {
        withAnimation(.spring(duration: 0.4)) { goalReachedFlash = true }
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            withAnimation(.easeOut(duration: 0.6)) { goalReachedFlash = false }
        }
    }

    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = lastTrackedDateInterval > 0
            ? Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: lastTrackedDateInterval))
            : nil

        if let last = lastDate {
            if last == today { return }
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            trackingStreak = (last == yesterday) ? trackingStreak + 1 : 1
        } else {
            trackingStreak = 1
        }
        lastTrackedDateInterval = today.timeIntervalSinceReferenceDate
    }
}
