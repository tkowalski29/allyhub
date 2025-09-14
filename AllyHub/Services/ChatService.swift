import Foundation

@MainActor
final class ChatService: ObservableObject {
    
    // MARK: - Data Models
    
    struct Conversation: Identifiable, Codable {
        let id: String
        let resume: String
    }
    
    struct ChatMessage: Identifiable, Codable {
        let id: String
        let date: String
        let question: String
        let answer: String
    }
    
    struct ConversationsResponse: Codable {
        let collection: [Conversation]
        let count: Int
    }
    
    struct MessagesResponse: Codable {
        let collection: [ChatMessage]
        let count: Int
    }
    
    struct MessageRequest: Codable {
        let conversationId: String
        let question: String
    }
    
    struct MessageResponse: Codable {
        let success: String
        let message: String
        let data: MessageData
        
        struct MessageData: Codable {
            let conversationId: String
            let answer: String
        }
    }
    
    struct CreateConversationResponse: Codable {
        let success: String
        let message: String
        let data: CreateConversationData
        
        struct CreateConversationData: Codable {
            let conversationId: String
        }
    }
    
    // MARK: - API Functions
    
    /// Fetch list of conversations (Collection endpoint)
    func fetchConversations(from url: String) async -> Result<ConversationsResponse, Error> {
        guard !url.isEmpty, let apiURL = URL(string: url) else {
            return .failure(ChatServiceError.invalidURL)
        }
        
        do {
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data("{}".utf8) // Empty JSON body
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(ChatServiceError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(ChatServiceError.serverError(httpResponse.statusCode))
            }
            
            let conversations = try JSONDecoder().decode(ConversationsResponse.self, from: data)
            return .success(conversations)
            
        } catch {
            return .failure(ChatServiceError.networkError(error))
        }
    }
    
    /// Get messages in a specific conversation (Get endpoint)
    func getConversationMessages(from url: String, conversationId: String) async -> Result<MessagesResponse, Error> {
        guard !url.isEmpty, let apiURL = URL(string: url) else {
            return .failure(ChatServiceError.invalidURL)
        }
        
        do {
            let requestBody = ["conversationId": conversationId]
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(ChatServiceError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(ChatServiceError.serverError(httpResponse.statusCode))
            }
            
            let messages = try JSONDecoder().decode(MessagesResponse.self, from: data)
            return .success(messages)
            
        } catch {
            return .failure(ChatServiceError.networkError(error))
        }
    }
    
    /// Create new conversation (Create endpoint)
    func createConversation(from url: String) async -> Result<CreateConversationResponse, Error> {
        guard !url.isEmpty, let apiURL = URL(string: url) else {
            return .failure(ChatServiceError.invalidURL)
        }
        
        do {
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data("{}".utf8) // Empty JSON body
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(ChatServiceError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(ChatServiceError.serverError(httpResponse.statusCode))
            }
            
            let createResponse = try JSONDecoder().decode(CreateConversationResponse.self, from: data)
            return .success(createResponse)
            
        } catch {
            return .failure(ChatServiceError.networkError(error))
        }
    }
    
    /// Send message and wait for response (Message endpoint)
    func sendMessage(to url: String, conversationId: String, question: String) async -> Result<MessageResponse, Error> {
        guard !url.isEmpty, let apiURL = URL(string: url) else {
            return .failure(ChatServiceError.invalidURL)
        }
        
        do {
            let messageRequest = MessageRequest(conversationId: conversationId, question: question)
            let jsonData = try JSONEncoder().encode(messageRequest)
            
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(ChatServiceError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(ChatServiceError.serverError(httpResponse.statusCode))
            }
            
            let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
            return .success(messageResponse)
            
        } catch {
            return .failure(ChatServiceError.networkError(error))
        }
    }
}

// MARK: - Error Types

enum ChatServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}