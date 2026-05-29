//
//  OnboardingView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "timer")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text("Welcome to Tally")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                Text("The simplest way to track billable hours across your clients. No subscription. No bloat. Just your time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "play.fill",
                    color: .green,
                    title: "Start tracking instantly",
                    description: "Tap start, pick a client, and go."
                )
                FeatureRow(
                    icon: "chart.bar.fill",
                    color: .blue,
                    title: "See your weekly progress",
                    description: "Know exactly how many hours you've logged."
                )
                FeatureRow(
                    icon: "bell.fill",
                    color: .orange,
                    title: "Get warned before you hit your limit",
                    description: "Set a weekly goal and get alerted at 80%."
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                hasSeenOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue)
                    )
                    .padding(.horizontal)
            }
            .accessibilityLabel("Get Started")
            .accessibilityHint("Opens the app and begins tracking your time")
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var color: Color
    var title: String
    var description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}
