//
//  CurrencyPreference.swift
//  Tally
//

import Foundation

enum CurrencyPreference {
    static let key = "preferredCurrencyCode"

    static var current: String {
        UserDefaults.standard.string(forKey: key) ?? "USD"
    }

    static func save(_ code: String) {
        UserDefaults.standard.set(code, forKey: key)
    }

    static let supported: [(code: String, label: String)] = [
        ("USD", "USD – US Dollar"),
        ("EUR", "EUR – Euro"),
        ("GBP", "GBP – British Pound"),
        ("CAD", "CAD – Canadian Dollar"),
        ("AUD", "AUD – Australian Dollar"),
        ("CHF", "CHF – Swiss Franc"),
        ("JPY", "JPY – Japanese Yen"),
        ("INR", "INR – Indian Rupee"),
        ("MXN", "MXN – Mexican Peso"),
        ("BRL", "BRL – Brazilian Real"),
    ]
}
