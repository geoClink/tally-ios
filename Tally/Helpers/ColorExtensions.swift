//
//  ColorExtensions.swift
//  Tally
//

import SwiftUI

extension Color {
    static var secondaryBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
}
