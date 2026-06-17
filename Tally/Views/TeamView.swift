//
//  TeamView.swift
//  Tally
//

import SwiftUI

struct TeamView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var showCreateWorkspace = false
    @State private var newWorkspaceName = ""
    @State private var newWorkspaceClient = ""
    @State private var showPaywall = false
    private let purchases = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if !purchases.hasTeamWorkspaces {
                    upsellView
                } else if tallyStore.workspaces.isEmpty {
                    emptyStateView
                } else {
                    workspaceList
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
                CreateWorkspaceSheet(name: $newWorkspaceName, clientName: $newWorkspaceClient) {
                    Task {
                        await tallyStore.createWorkspace(name: newWorkspaceName, clientName: newWorkspaceClient)
                        newWorkspaceName = ""
                        newWorkspaceClient = ""
                        showCreateWorkspace = false
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var workspaceList: some View {
        List {
            ForEach(tallyStore.workspaces) { workspace in
                NavigationLink {
                    WorkspaceDetailView(workspace: workspace)
                } label: {
                    WorkspaceCard(workspace: workspace)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if tallyStore.isOwner(of: workspace) {
                        DeleteWorkspaceButton(workspace: workspace)
                    }
                }
            }
        }
    }

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
}

// MARK: - Workspace Card (list row)

private struct WorkspaceCard: View {
    @Environment(TallyStore.self) var tallyStore
    let workspace: WorkspaceModel

    private var memberCount: Int {
        tallyStore.workspaceMembers.filter { $0.workspaceId == workspace.id }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workspace.name)
                .font(.headline)
            Text(workspace.clientName)
                .font(.caption)
                .foregroundStyle(.blue)
            HStack {
                Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(TimeFormatter.shortFormat(tallyStore.teamTotalWeeklyHours(for: workspace)))
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Text("this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task { await tallyStore.loadTeamSessions(for: workspace) }
    }
}

// MARK: - Delete Workspace Button

private struct DeleteWorkspaceButton: View {
    @Environment(TallyStore.self) var tallyStore
    let workspace: WorkspaceModel
    @State private var showConfirmation = false

    var body: some View {
        Button(role: .destructive) {
            showConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .alert("Delete Workspace", isPresented: $showConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await tallyStore.deleteWorkspace(workspace) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Delete \"\(workspace.name)\"? This removes all members and cannot be undone.")
        }
    }
}

// MARK: - Workspace Detail View

struct WorkspaceDetailView: View {
    @Environment(TallyStore.self) var tallyStore
    let workspace: WorkspaceModel
    @State private var showInvite = false
    @State private var showEdit = false
    @State private var inviteEmail = ""
    @State private var memberToRemove: WorkspaceMember?
    @State private var showRemoveConfirmation = false
    @State private var showLeaveConfirmation = false

    private var isOwner: Bool { tallyStore.isOwner(of: workspace) }
    private var isAdmin: Bool { tallyStore.isAdmin(of: workspace) }
    private var canManage: Bool { isOwner || isAdmin }

    private var members: [WorkspaceMember] {
        tallyStore.workspaceMembers.filter { $0.workspaceId == workspace.id }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    Text(workspace.clientName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("This Week") {
                HStack {
                    Text("Team Total")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(TimeFormatter.shortFormat(tallyStore.teamTotalWeeklyHours(for: workspace)))
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }

            Section("All Time") {
                HStack {
                    Text("Team Total")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(TimeFormatter.shortFormat(tallyStore.teamTotalAllTimeHours(for: workspace)))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Members") {
                ForEach(members) { member in
                    let canRemove = isOwner || (isAdmin && member.role != "admin")
                    MemberRow(
                        member: member,
                        canChangeRole: isOwner,
                        canRemove: canRemove,
                        isCurrentUser: member.invitedEmail.lowercased() == tallyStore.currentUserEmail?.lowercased(),
                        weeklyHours: member.userId.map { tallyStore.teamWeeklyHours(for: $0) },
                        allTimeHours: member.userId.map { tallyStore.teamAllTimeHours(for: $0) },
                        onChangeRole: { newRole in
                            Task { await tallyStore.changeMemberRole(member, to: newRole) }
                        },
                        onRemove: {
                            memberToRemove = member
                            showRemoveConfirmation = true
                        },
                        onAccept: {
                            Task { await tallyStore.acceptInvite(memberId: member.id) }
                        }
                    )
                }
            }

            if !isOwner {
                Section {
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Label("Leave Workspace", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .navigationTitle(workspace.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .primaryAction) {
                    Button { showEdit = true } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            if canManage {
                ToolbarItem(placement: .primaryAction) {
                    Button { showInvite = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .task {
            await tallyStore.loadTeamSessions(for: workspace)
        }
        .sheet(isPresented: $showInvite) {
            InviteMemberSheet(email: $inviteEmail) {
                Task {
                    await tallyStore.inviteMember(email: inviteEmail, to: workspace)
                    inviteEmail = ""
                    showInvite = false
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditWorkspaceSheet(workspace: workspace) { newName, newClient in
                Task {
                    await tallyStore.updateWorkspace(workspace, name: newName, clientName: newClient)
                    showEdit = false
                }
            }
        }
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
        .alert("Leave Workspace", isPresented: $showLeaveConfirmation) {
            Button("Leave", role: .destructive) {
                Task { await tallyStore.leaveWorkspace(workspace) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Leave \"\(workspace.name)\"? You'll need to be re-invited to rejoin.")
        }
    }
}

// MARK: - Member Row

private struct MemberRow: View {
    let member: WorkspaceMember
    let canChangeRole: Bool
    let canRemove: Bool
    let isCurrentUser: Bool
    let weeklyHours: Double?
    let allTimeHours: Double?
    let onChangeRole: (String) -> Void
    let onRemove: () -> Void
    let onAccept: () -> Void

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
            if !member.isPending {
                VStack(alignment: .trailing, spacing: 2) {
                    if let weekly = weeklyHours {
                        Text(TimeFormatter.shortFormat(weekly))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    if let allTime = allTimeHours {
                        Text("\(TimeFormatter.shortFormat(allTime)) total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if isCurrentUser && member.isPending {
                Button("Accept") { onAccept() }
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else if (canChangeRole || canRemove) && !member.isPending {
                Menu {
                    if canChangeRole {
                        Button {
                            onChangeRole(member.role == "admin" ? "member" : "admin")
                        } label: {
                            Label(
                                member.role == "admin" ? "Change to Member" : "Change to Admin",
                                systemImage: member.role == "admin" ? "person" : "shield"
                            )
                        }
                    }
                    if canRemove {
                        Button(role: .destructive) { onRemove() } label: {
                            Label("Remove", systemImage: "person.badge.minus")
                        }
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
    @Binding var clientName: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !clientName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Design Team", text: $name)
                } header: {
                    Text("Workspace Name")
                } footer: {
                    Text("A name for your team — like \"Design Team\" or \"Acme Project\".")
                }

                Section {
                    TextField("e.g. Acme Corp", text: $clientName)
                } header: {
                    Text("Client Name")
                } footer: {
                    Text("The client this workspace tracks time for. Team members log time using this exact client name.")
                }
            }
            .navigationTitle("New Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { onCreate() }
                        .disabled(!canCreate)
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
                    Text("Once they create a Tally account with this email, they'll automatically be added to the workspace.")
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

private struct EditWorkspaceSheet: View {
    let workspace: WorkspaceModel
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var clientName: String

    init(workspace: WorkspaceModel, onSave: @escaping (String, String) -> Void) {
        self.workspace = workspace
        self.onSave = onSave
        _name = State(initialValue: workspace.name)
        _clientName = State(initialValue: workspace.clientName)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !clientName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workspace name", text: $name)
                } header: {
                    Text("Workspace Name")
                }

                Section {
                    TextField("Client name", text: $clientName)
                } header: {
                    Text("Client Name")
                } footer: {
                    Text("Team members log time using this exact client name.")
                }
            }
            .navigationTitle("Edit Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name, clientName) }
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
