import SwiftUI

struct PermissionManagementView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: PermissionCategory = .all
    @State private var selectedRequest: PermissionRequest?

    var body: some View {
        NavigationSplitView {
            // Sidebar with categories
            List(selection: $selectedCategory) {
                NavigationLink("All Requests", value: PermissionCategory.all)

                Section("By Risk Level") {
                    NavigationLink("High Risk", value: PermissionCategory.highRisk)
                    NavigationLink("Medium Risk", value: PermissionCategory.mediumRisk)
                    NavigationLink("Low Risk", value: PermissionCategory.lowRisk)
                }

                Section("By Status") {
                    NavigationLink("Pending", value: PermissionCategory.pending)
                    NavigationLink("Approved", value: PermissionCategory.approved)
                    NavigationLink("Denied", value: PermissionCategory.denied)
                }
            }
            .listStyle(SidebarListStyle())
            .modifier(NavigationSplitViewColumnWidthModifier())
        } content: {
            // Main content - filtered permissions based on selection
            PermissionRequestsList(selectedCategory: selectedCategory, permissions: appState.pendingPermissions)
        } detail: {
            // Detail view when a permission is selected
            if let selectedRequest = selectedRequest {
                PermissionDetailView(request: selectedRequest)
            } else {
                Text("Select a permission request to view details")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NavigationSplitViewColumnWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(macOS 13.0, *) {
                content.navigationSplitViewColumnWidth(min: 200, ideal: 250)
            } else {
                content
            }
        }
    }
}

// MARK: - Supporting Enums and Structures
enum PermissionCategory: String, CaseIterable, Identifiable {
    case all = "All Requests"
    case highRisk = "High Risk"
    case mediumRisk = "Medium Risk"
    case lowRisk = "Low Risk"
    case pending = "Pending"
    case approved = "Approved"
    case denied = "Denied"

    var id: String { self.rawValue }
}

struct PermissionRequestsList: View {
    let selectedCategory: PermissionCategory
    let permissions: [PermissionRequest]

    var filteredPermissions: [PermissionRequest] {
        switch selectedCategory {
        case .all:
            return permissions
        case .highRisk:
            return permissions.filter { $0.permissionType.riskLevel == .high }
        case .mediumRisk:
            return permissions.filter { $0.permissionType.riskLevel == .medium }
        case .lowRisk:
            return permissions.filter { $0.permissionType.riskLevel == .low }
        case .pending:
            return permissions.filter { $0.status == .pending }
        case .approved:
            return permissions.filter { $0.status == .approved }
        case .denied:
            return permissions.filter { $0.status == .denied }
        }
    }

    var body: some View {
        List(filteredPermissions, selection: $selectedRequest) {
            PermissionRequestRow(request: $0)
        }
        .listStyle(PlainListStyle())
        .modifier(NavigationSplitViewColumnWidthModifier2())
        .onChange(of: selectedRequest) { _ in
            // Handle selection change if needed
        }
    }

    @State private var selectedRequest: PermissionRequest?
}

struct NavigationSplitViewColumnWidthModifier2: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(macOS 13.0, *) {
                content.navigationSplitViewColumnWidth(min: 400, ideal: 500)
            } else {
                content
            }
        }
    }
}

struct PermissionRequestRow: View {
    let request: PermissionRequest

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: request.permissionType.iconName)
                        .foregroundColor(iconColor)

                    Text(request.toolName)
                        .font(.headline)

                    Spacer()

                    riskBadge
                }

                Text(request.permissionType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(request.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text(formatDate(request.timestamp))
                        .font(.caption2)
                        .foregroundColor(Color.secondary.opacity(0.8))

                    Spacer()

                    statusBadge
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(rowBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var iconColor: Color {
        switch request.permissionType.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var riskBadge: some View {
        Text(request.permissionType.riskLevel.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(riskBadgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var riskBadgeColor: Color {
        switch request.permissionType.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var statusBadge: some View {
        Text(request.status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusBadgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var statusBadgeColor: Color {
        switch request.status {
        case .pending: return .gray
        case .approved: return .green
        case .denied: return .red
        case .expired: return .orange
        }
    }

    private var rowBackgroundColor: Color {
        request.status == .pending ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.6)
    }

    private var borderColor: Color {
        request.status == .pending ? iconColor.opacity(0.5) : Color(NSColor.separatorColor).opacity(0.3)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PermissionDetailView: View {
    let request: PermissionRequest

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: request.permissionType.iconName)
                        .font(.title)
                        .foregroundColor(iconColor)

                    VStack(alignment: .leading) {
                        Text(request.toolName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(request.permissionType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    riskBadge
                }

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)

                    Text(request.description)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)

                    LabeledContentWrapper<Text>(label: "Request Type", content: request.permissionType.rawValue)

                    LabeledContentWrapper<Text>(
                        label: "Risk Level",
                        content: request.permissionType.riskLevel.rawValue.capitalized,
                        color: riskLevelColor
                    )

                    LabeledContentWrapper<Text>(label: "Requested At", content: formatDate(request.timestamp))

                    LabeledContentWrapper<HStack<Text, Text>>(label: "Status", content: request.status.rawValue.capitalized) {
                        HStack {
                            statusBadge
                            Text(request.status.rawValue.capitalized)
                        }
                    }
                }

                // Actions
                if request.status == .pending {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Actions")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Button("Approve") {
                                // Approval action would go here
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Deny") {
                                // Deny action would go here
                            }
                            .buttonStyle(.bordered)

                            Button("More Info") {
                                // Show more detailed information
                            }
                            .buttonStyle(.borderless)

                            Spacer()
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconColor: Color {
        switch request.permissionType.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var riskLevelColor: Color {
        switch request.permissionType.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var riskBadge: some View {
        Text(request.permissionType.riskLevel.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(riskBadgeColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }

    private var riskBadgeColor: Color {
        switch request.permissionType.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var statusBadge: some View {
        Circle()
            .fill(statusBadgeColor)
            .frame(width: 8, height: 8)
    }

    private var statusBadgeColor: Color {
        switch request.status {
        case .pending: return .gray
        case .approved: return .green
        case .denied: return .red
        case .expired: return .orange
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LabeledContentWrapper<Content>: View where Content: View {
    let label: String
    let content: String
    let color: Color?
    let customContent: Content?

    init(label: String, content: String, color: Color? = nil) {
        self.label = label
        self.content = content
        self.color = color
        self.customContent = nil
    }

    init(label: String, content: String, color: Color? = nil, @ViewBuilder customContent: () -> Content) {
        self.label = label
        self.content = content
        self.color = color
        self.customContent = customContent()
    }

    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                if let customContent = customContent {
                    LabeledContent(label) {
                        customContent
                    }
                } else {
                    if let color = color {
                        LabeledContent(label) {
                            Text(content).foregroundColor(color)
                        }
                    } else {
                        LabeledContent(label, value: content)
                    }
                }
            } else {
                HStack {
                    Text("\(label):")
                        .fontWeight(.bold)
                    Spacer()
                    if let color = color {
                        Text(content).foregroundColor(color)
                    } else {
                        Text(content)
                    }
                }
            }
        }
    }
}