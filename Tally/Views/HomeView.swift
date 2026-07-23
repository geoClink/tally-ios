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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.requestReview) private var requestReview
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = TimerViewModel()

    // System orange fails WCAG AA (2.31:1 vs white). Dark amber passes at 5.3:1.
    private var accessibleOrange: Color {
        colorScheme == .dark ? .orange : Color(red: 0.65, green: 0.30, blue: 0.0)
    }

    // System red (~3.4:1 vs white) may fail depending on Inspector threshold. Dark red passes at 6.2:1.
    private var accessibleRed: Color {
        colorScheme == .dark ? .red : Color(red: 0.75, green: 0.0, blue: 0.04)
    }

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }
    @State private var showClientPicker = false
    @State private var showManualEntry = false
    @State private var showGoalSetting = false
    @State private var showTaskNote = false
    @State private var selectedClient = ""
    @State private var taskNoteText = ""
    @State private var pendingHours: Double = 0
    private var timerFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 52
        case .medium: return 58
        case .large: return 64
        case .xLarge: return 52
        case .xxLarge: return 44
        case .xxxLarge: return 38
        case .accessibility1: return 32
        case .accessibility2: return 28
        case .accessibility3, .accessibility4, .accessibility5: return 24
        default: return 64
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Weekly progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.headline)
                    ProgressBarView(value: tallyStore.weeklyHours, goal: tallyStore.weeklyGoal)

                    ForEach(tallyStore.clientGoals) { goal in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.client)
                                .font(.caption)
                                .foregroundStyle(captionColor)
                            ProgressBarView(
                                value: tallyStore.weeklyHours(for: goal.client),
                                goal: goal.weeklyHours
                            )
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
                .padding(.horizontal)
                
                if tallyStore.sessions.isEmpty && !viewModel.isRunning {
                    VStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("No sessions yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Tap Start to begin tracking your first session")
                            .font(.caption)
                            .foregroundStyle(captionColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
                
                // Timer display
                VStack(spacing: 8) {
                    if viewModel.isRunning {
                        Text(viewModel.activeClient)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Current client: \(viewModel.activeClient)")
                        
                        Text(TimeFormatter.format(viewModel.elapsedSeconds / 3600))
                            .font(.system(size: timerFontSize, weight: .thin, design: .monospaced))
                            .accessibilityLabel("Elapsed time: \(TimeFormatter.accessibleFormat(viewModel.elapsedSeconds / 3600))")
                            .accessibilityAddTraits(.updatesFrequently)
                        
                        Text(viewModel.isPaused ? "Paused" : "Running")
                            .font(.caption)
                            .foregroundStyle(viewModel.isPaused ? accessibleOrange : .green)
                            .accessibilityLabel("Timer status: \(viewModel.isPaused ? "Paused" : "Running")")
                    } else {
                        Text("00:00:00")
                            .font(.system(size: timerFontSize, weight: .thin, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("No active timer")
                        
                        Text("Ready to start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                .padding()
                
                // Controls
                HStack(spacing: 20) {
                    if !viewModel.isRunning {
                        Button {
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            showClientPicker = true
                        } label: {
                            Label("Start", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                        }
                        .accessibilityLabel("Start timer")
                        .accessibilityHint("Opens client picker to begin tracking time")
                    } else {
                        Button {
                            if viewModel.isPaused {
                                viewModel.resume()
                            } else {
                                viewModel.pause()
                            }
                        } label: {
                            Label(viewModel.isPaused ? "Resume" : "Pause",
                                  systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(accessibleOrange))
                        }
                        .accessibilityLabel(viewModel.isPaused ? "Resume timer" : "Pause timer")
                        .accessibilityHint(viewModel.isPaused ? "Resumes tracking time for \(viewModel.activeClient)" : "Pauses tracking time for \(viewModel.activeClient)")
                        
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
                                .background(RoundedRectangle(cornerRadius: 12).fill(accessibleRed))
                        }
                        .accessibilityLabel("Stop timer")
                        .accessibilityHint("Stops and saves the current session for \(viewModel.activeClient)")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Tally")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            showManualEntry = true
                        } label: {
                            Label("Log Hours Manually", systemImage: "pencil")
                        }
                        Button {
                            showGoalSetting = true
                        } label: {
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
                .presentationBackground(Color(.systemBackground))
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView()
            }
            .sheet(isPresented: $showGoalSetting) {
                GoalSettingView()
            }
            .sheet(isPresented: $showTaskNote) {
                TaskNoteSheet(
                    client: selectedClient,
                    hours: $pendingHours,
                    noteText: $taskNoteText,
                    onSkip: {
                        Task {
                            await tallyStore.addSession(client: selectedClient, hours: pendingHours, taskNote: nil)
                            taskNoteText = ""
                            showTaskNote = false
                            maybeRequestReview()
                        }
                    },
                    onSave: {
                        Task {
                            await tallyStore.addSession(client: selectedClient, hours: pendingHours, taskNote: taskNoteText.isEmpty ? nil : taskNoteText)
                            taskNoteText = ""
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
        // Prompt at 3 sessions, then every 15 after that
        if count == 3 || (count > 3 && (count - 3) % 15 == 0) {
            requestReview()
        }
    }
}
