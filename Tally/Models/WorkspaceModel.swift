//
//  WorkspaceModel.swift
//  Tally
//

import Foundation

struct WorkspaceModel: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let clientName: String
    let ownerId: String
    let createdAt: Date
    let weeklyGoal: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case clientName = "client_name"
        case ownerId    = "owner_id"
        case createdAt  = "created_at"
        case weeklyGoal = "weekly_goal"
    }
}

struct WorkspaceMember: Identifiable, Codable {
    let id: UUID
    let workspaceId: UUID
    let userId: String?
    let invitedEmail: String
    let role: String        // "owner" | "member"
    let acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId  = "workspace_id"
        case userId       = "user_id"
        case invitedEmail = "invited_email"
        case role
        case acceptedAt   = "accepted_at"
    }

    var isPending: Bool { acceptedAt == nil }
}

struct WorkspaceInviteInsert: Codable {
    let workspaceId: UUID
    let invitedEmail: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case workspaceId  = "workspace_id"
        case invitedEmail = "invited_email"
        case role
    }
}

struct WorkspaceInsert: Codable {
    let name: String
    let clientName: String
    let ownerId: String
    let weeklyGoal: Double

    enum CodingKeys: String, CodingKey {
        case name
        case clientName = "client_name"
        case ownerId    = "owner_id"
        case weeklyGoal = "weekly_goal"
    }
}
