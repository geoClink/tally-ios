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

    @State private var showClientPicker = false
    @State private var showManualEntry = false
    @State private var showGoalSetting = false
    @State private var showTaskNote = false
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
                        }
                    },
                    onSave: {
                        Task {
                            await tallyStore.addSession(client: selectedClient, hours: pendingHours, taskNote: taskNoteText.isEmpty ? nil : taskNoteText, isBillable: pendingBillable)
                            taskNoteText = ""
                            pendingBillable = true
                            showTaskNote = false
                            maybeRequestReview()
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

                if !viewModel.isRunning && tallyStore.weeklyHours > 0 {
                    Text("\(TimeFormatter.shortFormat(tallyStore.weeklyHours)) this week")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.6))
                        .padding(.top, 2)
                        .accessibilityLabel("\(TimeFormatter.accessibleFormat(tallyStore.weeklyHours)) tracked this week")
                }
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        } else {
            HStack(spacing: 16) {
                Button {
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
        if count == 3 || (count > 3 && (count - 3) % 15 == 0) {
            requestReview()
        }
    }
}
