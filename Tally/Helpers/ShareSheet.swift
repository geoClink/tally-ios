//
//  ShareSheet.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

#if os(iOS) || os(visionOS)
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: View {
    let url: URL

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Ready")
                .font(.headline)
            Text(url.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(minWidth: 280)
    }
}
#endif
