//
//  TeamView.swift
//  Tally
//

import SwiftUI

struct TeamView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var showCreateWorkspace = false
    @State private var showInvite = false
    @State private var selectedWorkspace: WorkspaceModel?
    @State private var newWorkspaceName = ""
    @State private var inviteEmail = ""
    @State private var showPaywall = false
    @State private var memberToRemove: WorkspaceMember?
    @State private var showRemoveConfirmation = false
    private let purchases = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if !purchases.hasTeamWorkspaces {
                    upsellView
                } else if tallyStore.workspaces.isEmpty {
                    emptyStateView
                } else {
                    workspaceListView
                }
            }
            .navigationTitle("Team")
            .toolbar {
                if purchases.hasTeamWorkspaces {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showCreateWorkspace = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task { await tallyStore.loadWorkspaces() }
            .sheet(isPresented: $showCreateWorkspace) {
                CreateWorkspaceSheet(name: $newWorkspaceName) {
                    Task {
                        await tallyStore.createWorkspace(name: newWorkspaceName)
                        newWorkspaceName = ""
                        showCreateWorkspace = false
                    }
                }
            }
            .sheet(isPresented: $showInvite) {
                InviteMemberSheet(email: $inviteEmail) {
                    guard let ws = selectedWorkspace else { return }
                    Task {
                        await tallyStore.inviteMember(email: inviteEmail, to: ws)
                        inviteEmail = ""
                        showInvite = false
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Remove Member", isPresented: $showRemoveConfirmation) {
                Button("Remove", role: .destructive) {
                    guard let member = memberToRemove else { return }
                    Task { await tallyStore.removeMember(member) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let member = memberToRemove {
                    Text("Remove \(member.invitedEmail) from this workspace?")
                }
            }
        }
    }

    // MARK: - Subviews

    private var upsellView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundStyle(.purple)
            VStack(spacing: 8) {
                Text("Team Workspaces")
                    .font(.title2.bold())
                Text("Invite team members, track shared clients, and see everyone's hours in one place.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button { showPaywall = true } label: {
                Label("Upgrade to Business", systemImage: "crown.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple))
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No workspaces yet")
                .font(.headline)
            Text("Create a workspace to start collaborating with your team.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button { showCreateWorkspace = true } label: {
                Label("Create Workspace", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
            }
            Spacer()
        }
    }

    private var workspaceListView: some View {
        List {
            ForEach(tallyStore.workspaces) { workspace in
                let isOwner = tallyStore.isOwner(of: workspace)

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(workspace.name).font(.headline)
                            Text("\(members(for: workspace).count) member\(members(for: workspace).count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isOwner {
                            Button {
                                selectedWorkspace = workspace
                                showInvite = true
                            } label: {
                                Label("Invite", systemImage: "person.badge.plus")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    ForEach(members(for: workspace)) { member in
                        MemberRow(
                            member: member,
                            isOwner: isOwner,
                            onChangeRole: { newRole in
                                Task { await tallyStore.changeMemberRole(member, to: newRole) }
                            },
                            onRemove: {
                                memberToRemove = member
                                showRemoveConfirmation = true
                            }
                        )
                    }
                }
            }
        }
    }

    private func members(for workspace: WorkspaceModel) -> [WorkspaceMember] {
        tallyStore.workspaceMembers.filter { $0.workspaceId == workspace.id }
    }
}

// MARK: - Member Row

private struct MemberRow: View {
    let member: WorkspaceMember
    let isOwner: Bool
    let onChangeRole: (String) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.invitedEmail)
                    .font(.subheadline)
                Text(member.isPending ? "Invite pending" : member.role.capitalized)
                    .font(.caption)
                    .foregroundStyle(member.isPending ? .orange : .secondary)
            }
            Spacer()
            if isOwner && !member.isPending {
                Menu {
                    Button {
                        onChangeRole(member.role == "admin" ? "member" : "admin")
                    } label: {
                        Label(
                            member.role == "admin" ? "Change to Member" : "Change to Admin",
                            systemImage: member.role == "admin" ? "person" : "shield"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Remove", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Sheets

private struct CreateWorkspaceSheet: View {
    @Binding var name: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Workspace Name") {
                    TextField("e.g. My Agency", text: $name)
                }
            }
            .navigationTitle("New Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { onCreate() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct InviteMemberSheet: View {
    @Binding var email: String
    let onInvite: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Email Address") {
                    TextField("colleague@example.com", text: $email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                }
                Section {
                    Text("They'll receive an email with a link to join your workspace. They'll need to install Tally to accept.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Invite Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invite") { onInvite() }
                        .disabled(!isValidEmail)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var isValidEmail: Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
}
