//
//  OnboardingView.swift
//  Tally
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0
    @State private var showPaywall = false

    var body: some View {
        TabView(selection: $page) {
            WelcomePage()
                .tag(0)
            FeaturesPage()
                .tag(1)
            PlansPage(showPaywall: $showPaywall, onGetStarted: {
                hasSeenOnboarding = true
            })
            .tag(2)
        }
#if os(iOS)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
#endif
        .animation(.easeInOut, value: page)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text("Welcome to Tally")
                    .font(.largeTitle.bold())
                Text("The simplest way to track billable hours. Start a timer, stop it, done.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "play.fill",     color: .green,  title: "One-tap tracking",       description: "Start a timer and pick a client in seconds.")
                FeatureRow(icon: "chart.bar.fill", color: .blue,   title: "Weekly progress",        description: "See hours logged per client at a glance.")
                FeatureRow(icon: "bell.fill",      color: .orange, title: "Goal notifications",     description: "Get warned at 80% of your weekly target.")
            }
            .padding(.horizontal, 32)
            Spacer()
            Text("Swipe to continue")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 48)
        }
    }
}

// MARK: - Page 2: Features

private struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text("Built for freelancers")
                    .font(.largeTitle.bold())
                Text("Everything you need to track, report, and invoice.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "applewatch",       color: .indigo,  title: "Apple Watch",      description: "Start and stop timers from your wrist.")
                FeatureRow(icon: "doc.text",          color: .teal,    title: "PDF invoices",     description: "Generate and share invoices in one tap.")
                FeatureRow(icon: "square.grid.2x2",   color: .purple,  title: "Home screen widget", description: "See your hours without opening the app.")
                FeatureRow(icon: "mic.fill",           color: .red,     title: "Siri shortcuts",  description: "\"Start Tally timer\" -- no unlock needed.")
            }
            .padding(.horizontal, 32)
            Spacer()
            Text("Swipe to see plans")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 48)
        }
    }
}

// MARK: - Page 3: Plans

private struct PlansPage: View {
    @Binding var showPaywall: Bool
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("Pick your plan")
                    .font(.largeTitle.bold())
                Text("Start free. Upgrade when you're ready.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                PlanRow(name: "Free",             price: "Always free",     highlight: false, features: "1 client · 7-day history · basic timer")
                PlanRow(name: "Tally Pro",        price: "$9.99 one-time",  highlight: true,  features: "Unlimited clients · CSV export · Watch · Widgets · Siri")
                PlanRow(name: "Tally Business",   price: "$4.99/month",     highlight: false, features: "Everything in Pro · Stripe invoicing · Team workspaces")
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onGetStarted()
                } label: {
                    Text("Start for Free")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                        .padding(.horizontal, 24)
                }

                Button {
                    showPaywall = true
                } label: {
                    Text("See upgrade options")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

private struct PlanRow: View {
    let name: String
    let price: String
    let highlight: Bool
    let features: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name).font(.headline)
                    if highlight {
                        Text("Popular")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
                Text(features)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(price)
                .font(.subheadline.bold())
                .foregroundStyle(highlight ? .blue : .primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(highlight ? Color.blue.opacity(0.05) : Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(highlight ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Shared

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
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}
