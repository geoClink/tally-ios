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
    @State private var newWorkspaceGoal: Double = 0
    @State private var showPaywall = false
    @State private var selectedWorkspace: WorkspaceModel?
    private let purchases = PurchaseManager.shared

    private var subscriptionExpired: Bool {
        !purchases.hasTeamWorkspaces && !tallyStore.workspaces.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: geo.size.width * 0.85)
                            .blur(radius: 90)
                            .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.08)

                        Circle()
                            .fill(Color.indigo.opacity(0.13))
                            .frame(width: geo.size.width * 0.7)
                            .blur(radius: 75)
                            .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.55)
                    }
                }
                .ignoresSafeArea()

                Group {
                    if !purchases.hasTeamWorkspaces {
                        upsellView
                    } else if tallyStore.workspaces.isEmpty {
                        emptyStateView
                    } else {
                        workspaceList
                    }
                }
            }
            .navigationTitle("Team")
            .toolbar {
                if purchases.hasTeamWorkspaces {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showCreateWorkspace = true } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Create workspace")
                    }
                }
            }
            .task { await tallyStore.loadWorkspaces() }
            .sheet(isPresented: $showCreateWorkspace) {
                CreateWorkspaceSheet(name: $newWorkspaceName, clientName: $newWorkspaceClient, weeklyGoal: $newWorkspaceGoal) {
                    Task {
                        await tallyStore.createWorkspace(name: newWorkspaceName, clientName: newWorkspaceClient, weeklyGoal: newWorkspaceGoal)
                        newWorkspaceName = ""
                        newWorkspaceClient = ""
                        newWorkspaceGoal = 0
                        showCreateWorkspace = false
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var workspaceList: some View {
        List {
            if subscriptionExpired {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Business subscription expired")
                                .font(.subheadline.bold())
                            Text("Your workspaces are read-only. Renew to invite members and manage teams.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Renew") { showPaywall = true }
                            .font(.caption.bold())
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(.orange)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.orange.opacity(0.12))
            }
            ForEach(tallyStore.workspaces) { workspace in
                Button {
                    selectedWorkspace = workspace
                } label: {
                    WorkspaceCard(workspace: workspace)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if tallyStore.isOwner(of: workspace) {
                        DeleteWorkspaceButton(workspace: workspace)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationDestination(item: $selectedWorkspace) { workspace in
            WorkspaceDetailView(workspace: workspace)
        }
    }

    private var upsellView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundStyle(.purple)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("Team Workspaces")
                    .font(.title2.bold())
                Text("Invite team members, track shared clients, and see everyone's hours in one place. Each member needs their own Business subscription.")
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
            .accessibilityHint("Opens upgrade options to unlock team workspaces")
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No workspaces yet")
                .font(.headline)
            Text("Create a workspace to start collaborating with your team.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button { showCreateWorkspace = true } label: {
                Label("Create Workspace", systemImage: "plus")
                    .font(.headline)
                    #if !os(visionOS)
                    .foregroundStyle(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                    #endif
            }
            #if os(visionOS)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            #endif
            Spacer()
        }
    }
}

// MARK: - Workspace Card (list row)

private struct WorkspaceCard: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.colorScheme) private var colorScheme
    let workspace: WorkspaceModel

    private var memberCount: Int {
        tallyStore.workspaceMembers.filter { $0.workspaceId == workspace.id }.count
    }

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workspace.name)
                        .font(.headline)
                    Text(workspace.clientName)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(TimeFormatter.shortFormat(tallyStore.teamTotalWeeklyHours(for: workspace)))
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                    Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(captionColor)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
            if workspace.weeklyGoal > 0 {
                let progress = min(tallyStore.teamTotalWeeklyHours(for: workspace) / workspace.weeklyGoal, 1.0)
                VStack(alignment: .leading, spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.2)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(progress >= 1 ? Color.green : Color.blue)
                                .frame(width: geo.size.width * progress, height: 5)
                        }
                    }
                    .frame(height: 5)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(Int(progress * 100)) percent of weekly goal")
                    Text("of \(TimeFormatter.shortFormat(workspace.weeklyGoal)) goal")
                        .font(.caption2)
                        .foregroundStyle(captionColor)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
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
    @Environment(\.colorScheme) private var colorScheme
    let workspace: WorkspaceModel
    @State private var showInvite = false
    private let purchases = PurchaseManager.shared

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }
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
        ZStack {
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.18))
                        .frame(width: geo.size.width * 0.85)
                        .blur(radius: 90)
                        .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.08)

                    Circle()
                        .fill(Color.indigo.opacity(0.12))
                        .frame(width: geo.size.width * 0.7)
                        .blur(radius: 75)
                        .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.55)
                }
            }
            .ignoresSafeArea()

        List {
            Section {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    Text(workspace.clientName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }

            Section("This Week") {
                HStack {
                    Text("Team Total")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if workspace.weeklyGoal > 0 {
                        Text("\(TimeFormatter.shortFormat(tallyStore.teamTotalWeeklyHours(for: workspace))) of \(TimeFormatter.shortFormat(workspace.weeklyGoal))")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    } else {
                        Text(TimeFormatter.shortFormat(tallyStore.teamTotalWeeklyHours(for: workspace)))
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                }
                if workspace.weeklyGoal > 0 {
                    let progress = min(tallyStore.teamTotalWeeklyHours(for: workspace) / workspace.weeklyGoal, 1.0)
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.2)).frame(height: 6)
                                RoundedRectangle(cornerRadius: 3).fill(progress >= 1 ? Color.green : Color.blue)
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(progress >= 1 ? "Weekly goal reached" : "\(Int(progress * 100)) percent of weekly goal, \(TimeFormatter.shortFormat(workspace.weeklyGoal - tallyStore.teamTotalWeeklyHours(for: workspace))) remaining")
                        HStack {
                            Text("\(Int(progress * 100))% of weekly goal")
                                .font(.caption)
                                .foregroundStyle(captionColor)
                            Spacer()
                            if progress < 1 {
                                Text("\(TimeFormatter.shortFormat(workspace.weeklyGoal - tallyStore.teamTotalWeeklyHours(for: workspace))) remaining")
                                    .font(.caption)
                                    .foregroundStyle(captionColor)
                            } else {
                                Text("Goal reached!")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        .accessibilityHidden(true)
                    }
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
                        weeklyHours: tallyStore.teamWeeklyHours(for: member.userId ?? member.invitedEmail),
                        allTimeHours: tallyStore.teamAllTimeHours(for: member.userId ?? member.invitedEmail),
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
        .scrollContentBackground(.hidden)
        } // ZStack
        .navigationTitle(workspace.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if isOwner && purchases.hasTeamWorkspaces {
                ToolbarItem(placement: .primaryAction) {
                    Button { showEdit = true } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit workspace")
                }
            }
            if canManage && purchases.hasTeamWorkspaces {
                ToolbarItem(placement: .primaryAction) {
                    Button { showInvite = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Invite member")
                }
            }
        }
        .task {
            await tallyStore.loadTeamSessions(for: workspace)
        }
        .sheet(isPresented: $showInvite) {
            InviteMemberSheet(email: $inviteEmail) {
                await tallyStore.inviteMember(email: inviteEmail, to: workspace)
                inviteEmail = ""
            }
        }
        .sheet(isPresented: $showEdit) {
            EditWorkspaceSheet(workspace: workspace) { newName, newClient, newGoal in
                Task {
                    await tallyStore.updateWorkspace(workspace, name: newName, clientName: newClient, weeklyGoal: newGoal)
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

    @Environment(\.colorScheme) private var colorScheme

    private var pendingColor: Color {
        colorScheme == .dark ? .orange : Color(red: 0.65, green: 0.30, blue: 0.0)
    }

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.invitedEmail)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(member.isPending ? "Invite pending" : member.role.capitalized)
                    .font(.caption)
                    .foregroundStyle(member.isPending ? pendingColor : .secondary)
            }
            .accessibilityElement(children: .combine)
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
                            .foregroundStyle(captionColor)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel({
                    var parts: [String] = []
                    if let weekly = weeklyHours { parts.append("\(TimeFormatter.accessibleFormat(weekly)) this week") }
                    if let allTime = allTimeHours { parts.append("\(TimeFormatter.accessibleFormat(allTime)) total") }
                    return parts.joined(separator: ", ")
                }())
            }
            if isCurrentUser && member.isPending {
                Button("Accept") { onAccept() }
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityHint("Accepts your invite to this workspace")
            } else if member.isPending && canRemove {
                Button(role: .destructive) { onRemove() } label: {
                    Label("Cancel Invite", systemImage: "xmark.circle")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel invite for \(member.invitedEmail)")
            } else if (canChangeRole || canRemove) {
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
                .accessibilityLabel("Manage \(member.invitedEmail)")
            }
        }
    }
}

// MARK: - Sheets

private struct CreateWorkspaceSheet: View {
    @Binding var name: String
    @Binding var clientName: String
    @Binding var weeklyGoal: Double
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var goalText = ""

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

                Section {
                    TextField("e.g. 80", text: $goalText)
                        .keyboardType(.decimalPad)
                        .onChange(of: goalText) { _, val in weeklyGoal = Double(val) ?? 0 }
                } header: {
                    Text("Weekly Hour Goal (optional)")
                } footer: {
                    Text("Total hours your team aims to log per week for this client.")
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
    let onInvite: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isSending = false
    @State private var didSend = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if didSend {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var formView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                }
                Text("Invite a Team Member")
                    .font(.title3.bold())
                Text("They'll get access once they sign in to Tally with this email address.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 28)

            // Email field
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                TextField("colleague@example.com", text: $email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    #endif
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 24)

            Spacer()

            // Send button
            Button {
                Task {
                    isSending = true
                    await onInvite()
                    isSending = false
                    withAnimation { didSend = true }
                    try? await Task.sleep(for: .seconds(1.6))
                    dismiss()
                }
            } label: {
                Group {
                    if isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                                #if !os(visionOS)
                                .tint(.white)
                                #endif
                            Text("Sending…")
                        }
                    } else {
                        Text("Send Invite")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                #if !os(visionOS)
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .background(isValidEmail && !isSending ? Color.blue : Color.blue.opacity(0.4),
                            in: RoundedRectangle(cornerRadius: 14))
                #endif
            }
            .disabled(!isValidEmail || isSending)
            #if os(visionOS)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            #endif
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)
            }
            Text("Invite Sent")
                .font(.title3.bold())
            Text("We'll add \(email) to the workspace as soon as they sign in.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var isValidEmail: Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
}

private struct EditWorkspaceSheet: View {
    let workspace: WorkspaceModel
    let onSave: (String, String, Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var clientName: String
    @State private var goalText: String

    init(workspace: WorkspaceModel, onSave: @escaping (String, String, Double) -> Void) {
        self.workspace = workspace
        self.onSave = onSave
        _name = State(initialValue: workspace.name)
        _clientName = State(initialValue: workspace.clientName)
        _goalText = State(initialValue: workspace.weeklyGoal > 0 ? String(Int(workspace.weeklyGoal)) : "")
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

                Section {
                    TextField("e.g. 80", text: $goalText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Weekly Hour Goal (optional)")
                } footer: {
                    Text("Total hours your team aims to log per week for this client.")
                }
            }
            .navigationTitle("Edit Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name, clientName, Double(goalText) ?? 0) }
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
