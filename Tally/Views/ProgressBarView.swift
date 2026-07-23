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

    @Environment(\.colorScheme) private var colorScheme

    // .secondary (#8A8A8E) is only 3.44:1 against white — fails 4.5:1 for 12pt caption text.
    // #666666 (white: 0.40) gives 5.74:1 in light mode; dark mode uses system secondary.
    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }
    
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
                    .foregroundStyle(captionColor)
                Spacer()
                Text("\(Int(progress * 100))% of \(TimeFormatter.shortFormat(goal)) goal")
                    .font(.caption)
                    .foregroundStyle(captionColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(progress >= 1.0 ? "Goal reached" : "\(Int(progress * 100)) percent")
    }
}
