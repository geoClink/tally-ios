//
//  StripeManager.swift
//  Tally
//

import Foundation

struct StripeInvoiceResult {
    let invoiceUrl: URL
    let invoiceId: String
    let amountDue: Int  // cents
}

enum StripeManager {
    // Your Supabase project URL -- matches SupabaseManager
    private static let functionURL = URL(string: "https://fcmfuxoblbtxigknwhpz.supabase.co/functions/v1/create-stripe-invoice")!

    static func createInvoice(
        clientEmail: String,
        clientName: String,
        lineItems: [(description: String, hours: Double, rate: Double)],
        authToken: String
    ) async throws -> StripeInvoiceResult {

        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "clientEmail": clientEmail,
            "clientName": clientName,
            "lineItems": lineItems.map {
                ["description": $0.description, "hours": $0.hours, "rate": $0.rate]
            }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw NSError(domain: "Stripe", code: 0, userInfo: [NSLocalizedDescriptionKey: msg ?? "Unknown error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["invoiceUrl"] as? String,
              let url = URL(string: urlString),
              let invoiceId = json["invoiceId"] as? String,
              let amountDue = json["amountDue"] as? Int
        else {
            throw NSError(domain: "Stripe", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        return StripeInvoiceResult(invoiceUrl: url, invoiceId: invoiceId, amountDue: amountDue)
    }
}
