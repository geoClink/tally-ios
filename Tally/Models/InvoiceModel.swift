//
//  InvoiceModel.swift
//  Tally
//

import Foundation

struct InvoiceModel: Codable, Identifiable {
    let id: UUID
    let invoiceNumber: String
    let yourName: String?
    let client: String
    let clientEmail: String?
    let startDate: String
    let endDate: String
    let totalHours: Double
    let hourlyRate: Double
    let totalAmount: Double
    let taxRate: Double
    let taxAmount: Double
    let memo: String?
    var status: String
    let stripeInvoiceId: String?
    let stripeInvoiceUrl: String?
    let lineItems: [InvoiceLineItem]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case invoiceNumber  = "invoice_number"
        case yourName       = "your_name"
        case client
        case clientEmail    = "client_email"
        case startDate      = "start_date"
        case endDate        = "end_date"
        case totalHours     = "total_hours"
        case hourlyRate     = "hourly_rate"
        case totalAmount    = "total_amount"
        case taxRate        = "tax_rate"
        case taxAmount      = "tax_amount"
        case memo
        case status
        case stripeInvoiceId  = "stripe_invoice_id"
        case stripeInvoiceUrl = "stripe_invoice_url"
        case lineItems      = "line_items"
        case createdAt      = "created_at"
    }
}

struct InvoiceLineItem: Codable {
    let date: String?
    let hours: Double
    let taskNote: String?
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case date, hours, amount
        case taskNote = "task_note"
    }
}

struct InvoiceInsert: Encodable {
    let userId: String
    let invoiceNumber: String
    let yourName: String?
    let client: String
    let clientEmail: String?
    let startDate: String
    let endDate: String
    let totalHours: Double
    let hourlyRate: Double
    let totalAmount: Double
    let taxRate: Double
    let taxAmount: Double
    let memo: String?
    let status: String
    let lineItems: [InvoiceLineItem]

    enum CodingKeys: String, CodingKey {
        case userId         = "user_id"
        case invoiceNumber  = "invoice_number"
        case yourName       = "your_name"
        case client
        case clientEmail    = "client_email"
        case startDate      = "start_date"
        case endDate        = "end_date"
        case totalHours     = "total_hours"
        case hourlyRate     = "hourly_rate"
        case totalAmount    = "total_amount"
        case taxRate        = "tax_rate"
        case taxAmount      = "tax_amount"
        case memo
        case status
        case lineItems      = "line_items"
    }
}
