//
//  AllClientsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct AllClientsView: View {
    let clients: [(String, Double)]
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filtered: [(String, Double)] {
        if searchText.isEmpty {
            return clients
        }
        return clients.filter { $0.0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.0) { client, hours in
                    HStack {
                        Text(client)
                        Spacer()
                        Text(TimeFormatter.shortFormat(hours))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(client): \(TimeFormatter.accessibleFormat(hours))")
                }
            }
            .searchable(text: $searchText, prompt: "Search clients")
            .navigationTitle("All Clients")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
