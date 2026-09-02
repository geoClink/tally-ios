//
//  OnboardingView.swift
//  Tally
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0
    @State private var showPaywall = false
    @State private var animateBlobs = false

    var body: some View {
        ZStack {
            backgroundCircles

            TabView(selection: $page) {
                WelcomePage().tag(0)
                FeaturesPage().tag(1)
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
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { animateBlobs = true }
    }

    private var backgroundCircles: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.22))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 90)
                    .offset(
                        x: geo.size.width * 0.35 + (animateBlobs ? 18 : -18),
                        y: -geo.size.height * 0.12 + (animateBlobs ? -12 : 12)
                    )
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBlobs)

                Circle()
                    .fill(Color.indigo.opacity(0.18))
                    .frame(width: geo.size.width * 0.75)
                    .blur(radius: 75)
                    .offset(
                        x: -geo.size.width * 0.3 + (animateBlobs ? -14 : 14),
                        y: geo.size.height * 0.38 + (animateBlobs ? 12 : -12)
                    )
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animateBlobs)

                Circle()
                    .fill(Color.cyan.opacity(0.13))
                    .frame(width: geo.size.width * 0.55)
                    .blur(radius: 55)
                    .offset(
                        x: geo.size.width * 0.15 + (animateBlobs ? 10 : -10),
                        y: geo.size.height * 0.68 + (animateBlobs ? -18 : 18)
                    )
                    .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: animateBlobs)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    @State private var pulse = false
    @State private var hintOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            pageIcon(systemName: "timer", colors: [.blue, .indigo], pulse: pulse)
                .onAppear { pulse = true }

            VStack(spacing: 10) {
                Text("Welcome to Tally")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading, endPoint: .trailing
                    ))
                Text("The simplest way to track billable hours.\nStart a timer, stop it, done.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "play.fill",               color: .green,  title: "One-tap timer",       description: "Pick a client and go. Stop when done — Tally handles the rest.")
                FeatureRow(icon: "dollarsign.circle.fill",  color: .teal,   title: "Billable tracking",   description: "Mark hours billable or non-billable and see the split in reports.")
                FeatureRow(icon: "target",                  color: .orange, title: "Per-client goals",    description: "Set weekly targets per client and watch progress in real time.")
            }
            .padding(.horizontal, 24)

            Spacer()

            swipeHint(label: "Swipe to continue", hintOffset: hintOffset)
                .padding(.bottom, 56)
                .onAppear { hintOffset = 5 }
        }
    }
}

// MARK: - Page 2: Features

private struct FeaturesPage: View {
    @State private var pulse = false
    @State private var hintOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            pageIcon(systemName: "sparkles", colors: [.indigo, .purple], pulse: pulse)
                .onAppear { pulse = true }

            VStack(spacing: 10) {
                Text("Built for freelancers")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .leading, endPoint: .trailing
                    ))
                Text("Track time, hit goals, and get paid — all in one place.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "applewatch",      color: .indigo,  title: "Apple Watch + Live Activity", description: "Track from your wrist or see the timer live on your lock screen.")
                FeatureRow(icon: "doc.text",        color: .teal,    title: "PDF invoices",                description: "Generate and send a professional invoice in one tap.")
                FeatureRow(icon: "square.grid.2x2", color: .purple,  title: "Home screen widget",          description: "See today's hours without opening the app.")
                FeatureRow(icon: "mic.fill",        color: .red,     title: "Siri shortcuts",              description: "\"Start Tally timer\" — hands-free, no unlock needed.")
            }
            .padding(.horizontal, 24)

            Spacer()

            swipeHint(label: "Swipe to see plans", hintOffset: hintOffset)
                .padding(.bottom, 56)
                .onAppear { hintOffset = 5 }
        }
    }
}

// MARK: - Page 3: Plans

private struct PlansPage: View {
    @Binding var showPaywall: Bool
    let onGetStarted: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            pageIcon(systemName: "crown.fill", colors: [.yellow, .orange], pulse: pulse)
                .onAppear { pulse = true }

            VStack(spacing: 8) {
                Text("Pick your plan")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading, endPoint: .trailing
                    ))
                Text("Start free. Upgrade when you're ready.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                PlanRow(name: "Free",           price: "Always free",    highlight: false, features: "5 clients · 7-day history · basic timer")
                PlanRow(name: "Tally Pro",      price: "$9.99 one-time", highlight: true,  features: "Unlimited clients · CSV export · Watch · Widgets · Siri")
                PlanRow(name: "Tally Business", price: "$4.99/month",    highlight: false, features: "Everything in Pro · Stripe invoicing · Team workspaces")
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 16) {
                Button { showPaywall = true } label: {
                    Text("See upgrade options")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Button { onGetStarted() } label: {
                    Text("Start for Free")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: .blue.opacity(0.35), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 64)
        }
    }
}

// MARK: - Shared helpers

private func pageIcon(systemName: String, colors: [Color], pulse: Bool) -> some View {
    ZStack {
        Circle()
            .fill(colors[0].opacity(0.07))
            .frame(width: 148, height: 148)
            .scaleEffect(pulse ? 1.18 : 0.88)
            .blur(radius: 20)

        Circle()
            .fill(LinearGradient(
                colors: [colors[0].opacity(0.2), colors.last!.opacity(0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 112, height: 112)
            .scaleEffect(pulse ? 1.05 : 1.0)

        Circle()
            .stroke(
                LinearGradient(colors: [colors[0].opacity(0.6), colors.last!.opacity(0.3)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1.5
            )
            .frame(width: 112, height: 112)

        Image(systemName: systemName)
            .font(.system(size: 44, weight: .light))
            .foregroundStyle(LinearGradient(
                colors: colors,
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
    }
    .accessibilityHidden(true)
    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)
}

private func swipeHint(label: String, hintOffset: CGFloat) -> some View {
    HStack(spacing: 5) {
        Text(label)
            .font(.caption)
            .foregroundStyle(.tertiary)
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .offset(x: hintOffset)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: hintOffset)
    }
}

// MARK: - Plan Row

private struct PlanRow: View {
    let name: String
    let price: String
    let highlight: Bool
    let features: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name).font(.headline)
                    if highlight {
                        Text("Popular")
                            .font(.caption2.bold())
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(
                                LinearGradient(colors: [.blue.opacity(0.18), .indigo.opacity(0.12)],
                                               startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
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
                .foregroundStyle(highlight
                    ? AnyShapeStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.primary)
                )
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    highlight
                        ? AnyShapeStyle(LinearGradient(colors: [.blue.opacity(0.6), .indigo.opacity(0.4)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.primary.opacity(0.08)),
                    lineWidth: highlight ? 1.5 : 1
                )
        )
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    var icon: String
    var color: Color
    var title: String
    var description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [color.opacity(0.22), color.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}
