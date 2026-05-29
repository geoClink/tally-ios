//
//  ProgressBarView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ProgressBarView: View {
    var value: Double
    var goal: Double
    
    private var progress: Double {
        min(value / goal, 1.0)
    }
    
    private var barColor: Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .blue
    }
    
    private var accessibilityDescription: String {
        let pct = Int(progress * 100)
        if progress >= 1.0 {
            return "Weekly goal reached. \(TimeFormatter.shortFormat(value)) logged of \(TimeFormatter.shortFormat(goal)) goal."
        } else if progress >= 0.8 {
            return "Approaching weekly limit. \(TimeFormatter.shortFormat(value)) logged of \(TimeFormatter.shortFormat(goal)) goal. \(pct) percent complete."
        }
        return "\(TimeFormatter.shortFormat(value)) logged of \(TimeFormatter.shortFormat(goal)) weekly goal. \(pct) percent complete."
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 12)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text(TimeFormatter.shortFormat(value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))% of \(TimeFormatter.shortFormat(goal)) goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(progress >= 1.0 ? "Goal reached" : "\(Int(progress * 100)) percent")
    }
}
