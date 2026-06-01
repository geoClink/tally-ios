//
//  ErrorHandler.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation

@MainActor
@Observable
class ErrorHandler {
    static let shared = ErrorHandler()
    
    var currentError: String?
    var showError = false
    
    func handle(_ error: Error, context: String = "") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        currentError = message
        showError = true
        print("Error -- \(message)")
    }
    
    func handle(_ message: String) {
        currentError = message
        showError = true
        print("Error -- \(message)")
    }
}
