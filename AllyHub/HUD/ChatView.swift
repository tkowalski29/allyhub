import SwiftUI

// Observable class for external triggers
class ChatViewModel: ObservableObject {
    @Published var shouldCreateNewConversation = false
    @Published var shouldRefresh = false
    
    func triggerNewConversation() {
        shouldCreateNewConversation = true
    }
    
    func triggerRefresh() {
        shouldRefresh = true
    }
}

struct ChatView: View {
    @ObservedObject var communicationSettings: CommunicationSettings
    @StateObject private var chatService = ChatService()
    @ObservedObject var viewModel: ChatViewModel
    private let cacheManager = CacheManager.shared
    
    @State private var chatInputText = ""
    @AppStorage("activeConversationId") private var activeConversationId: String?
    @State private var conversationsAccordionExpanded = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var conversations: [ApiConversation] = []
    @State private var isWaitingForResponse = false
    
    // API conversation structure
    struct ApiConversation: Identifiable, Codable {
        let id: String
        let resume: String
        
        var title: String {
            return resume.isEmpty ? "Untitled Conversation" : resume
        }
    }
    
    // MARK: - Data Models
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages area (takes up ~100% of available height)
            if activeConversationId != nil {
                chatMessagesView
            } else {
                placeholderView
            }
            
            // Conversations list accordion at bottom
            conversationsListAccordion
        }
        .onAppear {
            loadCachedConversations()
            loadConversations()
        }
        .onReceive(viewModel.$shouldCreateNewConversation) { shouldCreate in
            if shouldCreate {
                createNewConversation()
                viewModel.shouldCreateNewConversation = false
            }
        }
        .onReceive(viewModel.$shouldRefresh) { shouldRefresh in
            if shouldRefresh {
                refreshChat()
                viewModel.shouldRefresh = false
            }
        }
    }
    
    // MARK: - Chat Messages View
    private var chatMessagesView: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(chatMessages) { message in
                            chatBubble(message)
                        }
                        
                        // Typing indicator
                        if isWaitingForResponse {
                            typingIndicator
                                .id("typing-indicator")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .overlay(
                    // Custom scrollbar
                    customScrollbar,
                    alignment: .trailing
                )
                .onChange(of: chatMessages.count) { _ in
                    if let lastMessage = chatMessages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isWaitingForResponse) { _ in
                    if isWaitingForResponse {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing-indicator", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input
            messageInputField
        }
    }
    
    // MARK: - Chat Bubble
    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            Text(message.content.replacingOccurrences(of: "\\n", with: "\n"))
                .font(.system(size: 14))
                .foregroundColor(message.isUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                )
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                .textSelection(.enabled)
                .contextMenu {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content.replacingOccurrences(of: "\\n", with: "\n"), forType: .string)
                    }
                }
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.iBeam.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack {
            Spacer(minLength: 60)
            
            Text("...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Custom Scrollbar
    private var customScrollbar: some View {
        VStack {
            if chatMessages.count > 5 { // Only show scrollbar when there are enough messages
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 80)
                    .padding(.trailing, 4)
                    .padding(.vertical, 8)
                    .opacity(chatMessages.isEmpty ? 0 : 0.6)
            }
        }
    }
    
    // MARK: - Message Input Field
    private var messageInputField: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $chatInputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .onSubmit {
                    if !chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendMessage()
                    }
                }
            
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ] : [
                                    Color.blue.opacity(0.8),
                                    Color.blue.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(
                                    chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                    Color.white.opacity(0.2) : Color.blue.opacity(0.4), 
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(
                            chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                            .white.opacity(0.4) : .white
                        )
                }
            }
            .disabled(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
            .scaleEffect(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Placeholder View
    private var placeholderView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    Text("No Active Conversation")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Create a new conversation to start chatting")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Conversations List Accordion
    private var conversationsListAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    conversationsAccordionExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Conversations")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    if !conversations.isEmpty {
                        Text("(\(conversations.count))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: conversationsAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(conversationsAccordionExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.3), value: conversationsAccordionExpanded)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .buttonStyle(.plain)
            
            if conversationsAccordionExpanded {
                conversationsListView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .slide),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    // MARK: - Conversations List View
    private var conversationsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 6) {
                if conversations.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No conversations yet")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(conversations) { conversation in
                        conversationListItem(conversation)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 180)
        .background(Color.black.opacity(0.1))
        .overlay(
            // Custom scrollbar indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 4)
                .padding(.trailing, 2),
            alignment: .trailing
        )
    }
    
    private func conversationListItem(_ conversation: ApiConversation) -> some View {
        Button(action: {
            switchToConversation(conversation)
        }) {
            HStack(spacing: 12) {
                // Chat bubble icon
                Image(systemName: "bubble.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(activeConversationId == conversation.id ? .blue : .white.opacity(0.6))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(conversation.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(String(conversation.id.prefix(8)) + "...")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if activeConversationId == conversation.id {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        activeConversationId == conversation.id 
                        ? Color.white.opacity(0.15) 
                        : Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                activeConversationId == conversation.id 
                                ? Color.blue.opacity(0.4) 
                                : Color.clear, 
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(activeConversationId == conversation.id ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: activeConversationId)
    }
    
    private func switchToConversation(_ conversation: ApiConversation) {
        activeConversationId = conversation.id
        loadConversationMessages(conversation.id)
        
        // Close conversations accordion
        withAnimation {
            conversationsAccordionExpanded = false
        }
    }
    
    private func loadConversationMessages(_ conversationId: String) {
        // First, try to load from cache
        if let cachedMessages = cacheManager.getCachedConversationHistory() {
            chatMessages.removeAll()

            // Convert cached API messages to local ChatMessage format
            for apiMessage in cachedMessages {
                chatMessages.append(ChatMessage(content: apiMessage.question, isUser: true))
                chatMessages.append(ChatMessage(content: apiMessage.answer, isUser: false))
            }
            print("📱 [ChatView] Loaded \(cachedMessages.count) messages from cache for conversation: \(conversationId)")
            return
        }

        // If no cache or cache is stale, load from API
        Task {
            let result = await chatService.getConversationMessages(
                from: communicationSettings.chatGetConversationURL,
                conversationId: conversationId
            )

            await MainActor.run {
                switch result {
                case .success(let response):
                    chatMessages.removeAll()

                    // Convert API messages to local ChatMessage format
                    for apiMessage in response.collection {
                        chatMessages.append(ChatMessage(content: apiMessage.question, isUser: true))
                        chatMessages.append(ChatMessage(content: apiMessage.answer, isUser: false))
                    }

                    // Cache the conversation history
                    cacheManager.cacheConversationHistory(response.collection, conversationId: conversationId)

                    print("✅ Loaded \(response.collection.count) messages for conversation: \(conversationId)")

                case .failure(let error):
                    print("❌ Failed to load conversation messages: \(error.localizedDescription)")
                    chatMessages.removeAll()
                    chatMessages.append(ChatMessage(content: "Failed to load conversation. Try again later.", isUser: false))
                }
            }
        }
    }
    
    // MARK: - API Functions
    func createNewConversation() {
        Task {
            let result = await chatService.createConversation(from: communicationSettings.chatCreateConversationURL)
            
            await MainActor.run {
                switch result {
                case .success(let response):
                    activeConversationId = response.data.conversationId
                    chatMessages.removeAll()
                    conversationsAccordionExpanded = false
                    
                    // Reload conversations to get the updated list
                    loadConversations()
                    
                    print("✅ New conversation created: \(response.data.conversationId)")
                    
                case .failure(let error):
                    print("❌ Failed to create conversation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        guard let conversationId = activeConversationId else { return }
        
        // Add user message immediately
        chatMessages.append(ChatMessage(content: messageText, isUser: true))
        chatInputText = ""
        
        // Show typing indicator
        isWaitingForResponse = true
        
        Task {
            let result = await chatService.sendMessage(
                to: communicationSettings.chatMessageURL,
                conversationId: conversationId,
                question: messageText
            )
            
            await MainActor.run {
                // Hide typing indicator
                isWaitingForResponse = false
                
                switch result {
                case .success(let response):
                    chatMessages.append(ChatMessage(content: response.data.answer.replacingOccurrences(of: "\\n", with: "\n"), isUser: false))

                    // Invalidate cache after successful message send to ensure fresh data on next load
                    cacheManager.clearConversationHistoryCache()

                    print("✅ Message sent successfully")

                case .failure(let error):
                    print("❌ Failed to send message: \(error.localizedDescription)")
                    chatMessages.append(ChatMessage(
                        content: "Failed to send message. Please try again.",
                        isUser: false
                    ))
                }
            }
        }
    }
    
    private func refreshChat() {
        print("🔄 Refreshing chat data...")
        
        // Refresh conversations list
        loadConversations()
        
        // Refresh active conversation messages if there's one active
        if let activeConversationId = activeConversationId {
            loadConversationMessages(activeConversationId)
        }
    }
    
    private func loadCachedConversations() {
        if let cachedConversations = cacheManager.getCachedConversations() {
            conversations = cachedConversations.map { chatServiceConversation in
                ApiConversation(
                    id: chatServiceConversation.id,
                    resume: chatServiceConversation.resume
                )
            }
            print("📱 [ChatView] Loaded \(conversations.count) conversations from cache")
            
            // Load active conversation if one is saved
            if let savedActiveConversationId = activeConversationId,
               conversations.contains(where: { $0.id == savedActiveConversationId }) {
                loadConversationMessages(savedActiveConversationId)
                print("📱 [ChatView] Restored active conversation from cache: \(savedActiveConversationId)")
            }
        }
    }
    
    private func loadConversations() {
        Task {
            let result = await chatService.fetchConversations(from: communicationSettings.chatHistoryURL)
            
            await MainActor.run {
                switch result {
                case .success(let response):
                    // Convert API conversations to our local format
                    conversations = response.collection.map { apiConversation in
                        ApiConversation(
                            id: apiConversation.id,
                            resume: apiConversation.resume
                        )
                    }
                    print("✅ Loaded \(conversations.count) conversations from API")
                    
                    // Cache the conversations
                    let conversationsForCache = response.collection
                    cacheManager.cacheConversations(conversationsForCache)
                    
                    // Load active conversation if one is saved
                    if let savedActiveConversationId = activeConversationId,
                       conversations.contains(where: { $0.id == savedActiveConversationId }) {
                        loadConversationMessages(savedActiveConversationId)
                        print("✅ Restored active conversation: \(savedActiveConversationId)")
                    }
                    
                case .failure(let error):
                    print("❌ Failed to load conversations: \(error.localizedDescription)")
                    conversations.removeAll()
                }
            }
        }
    }
}