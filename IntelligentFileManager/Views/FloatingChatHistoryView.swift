import SwiftUI
import Combine

struct FloatingChatHistoryView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @State private var isExpanded = false
    @State private var searchQuery = ""
    @State private var conversations: [ConversationThread] = []
    @State private var selectedThread: ConversationThread? = nil
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    if isExpanded {
                        chatPanel
                            .transition(.scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity))
                    }
                    chatToggleButton
                }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isExpanded)
        .sheet(item: $selectedThread) { thread in
            ThreadDetailSheet(thread: thread)
        }
    }

    // MARK: - Chat Panel

    private var chatPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Conversation History")
                    .font(.headline)
                Spacer()
                Button { isExpanded = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search conversations", text: $searchQuery)
                    .onChange(of: searchQuery) { _, query in
                        searchTask?.cancel()
                        searchTask = Task {
                            try? await Task.sleep(for: .milliseconds(300))
                            guard !Task.isCancelled else { return }
                            conversations = await appEnvironment.offlineAssistantService.search(query: query)
                        }
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // List
            if conversations.isEmpty {
                Text("No conversations yet.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(conversations, id: \.id) { thread in
                            Button {
                                selectedThread = thread
                            } label: {
                                ConversationRow(thread: thread)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 12, y: 4)
        .frame(width: 320)
        .task {
            conversations = await appEnvironment.offlineAssistantService.search(query: "")
        }
    }

    // MARK: - Toggle Button

    private var chatToggleButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            Image(systemName: isExpanded ? "bubble.left.fill" : "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 6, y: 3)
        }
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let thread: ConversationThread

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(thread.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(thread.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Thread Detail Sheet

private struct ThreadDetailSheet: View {
    let thread: ConversationThread
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(thread.messages, id: \.id) { message in
                VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                    HStack {
                        if message.role == "user" { Spacer() }
                        Text(message.content)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(message.role == "user" ? Color.blue : Color.gray.opacity(0.15))
                            .foregroundStyle(message.role == "user" ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .frame(maxWidth: 280, alignment: message.role == "user" ? .trailing : .leading)
                        if message.role != "user" { Spacer() }
                    }
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle(thread.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        FloatingChatHistoryView()
            .environmentObject(AppEnvironment(modelContainer: try! ModelContainerProvider.preview()))
    }
}
