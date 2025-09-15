import SwiftUI
import Foundation

@MainActor
class NotificationsManager: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var unreadNotificationsCount: Int = 0
    @Published var expandedNotificationId: UUID?
    
    private let communicationSettings: CommunicationSettings
    
    init(communicationSettings: CommunicationSettings) {
        self.communicationSettings = communicationSettings
    }
    
    // MARK: - Public Methods
    
    func fetchNotifications() {
        print("🔄 [NotificationsManager] Starting fetchNotifications()")
        
        guard !communicationSettings.notificationsFetchURL.isEmpty else {
            print("❌ [NotificationsManager] Notifications fetch URL is empty")
            createFallbackNotifications()
            return
        }
        
        print("🌐 [NotificationsManager] Fetch URL: \(communicationSettings.notificationsFetchURL)")
        
        guard let url = URL(string: communicationSettings.notificationsFetchURL) else {
            print("❌ [NotificationsManager] Invalid notifications fetch URL: \(communicationSettings.notificationsFetchURL)")
            createFallbackNotifications()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "userId": "default_user",
            "limit": 50
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to serialize notifications request: \(error)")
            return
        }
        
        print("🚀 [NotificationsManager] Sending POST request to: \(url)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [NotificationsManager] Fetch error: \(error.localizedDescription)")
                    self.createFallbackNotifications()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 [NotificationsManager] HTTP Response: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("❌ [NotificationsManager] No data received from API")
                    self.createFallbackNotifications()
                    return
                }
                
                print("📦 [NotificationsManager] Received \(data.count) bytes of data")
                
                // Handle completely empty response (0 bytes)
                if data.count == 0 {
                    print("✅ [NotificationsManager] Server returned empty response - this is normal")
                    self.notifications = []
                    self.unreadNotificationsCount = 0
                    return
                }
                
                // First try to decode as array containing structured response
                if let arrayResponse = try? JSONDecoder().decode([NotificationsResponse].self, from: data),
                   let firstResponse = arrayResponse.first {
                    print("✅ [NotificationsManager] Decoded as array containing structured response")
                    self.processNotificationsResponse(firstResponse)
                } else if let directResponse = try? JSONDecoder().decode(NotificationsResponse.self, from: data) {
                    // Fallback: try to decode as direct structured response
                    print("✅ [NotificationsManager] Decoded as direct structured response")
                    self.processNotificationsResponse(directResponse)
                } else if let apiNotifications = try? JSONDecoder().decode([APINotification].self, from: data) {
                    // Final fallback: try to decode as direct array of notifications
                    print("✅ [NotificationsManager] Decoded as direct array of notifications")
                    self.processNotificationsArray(apiNotifications)
                } else {
                    // Check if it's a valid but empty response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📝 [NotificationsManager] Raw response: \(jsonString)")
                        
                        // Check for empty array or empty response patterns
                        let trimmedResponse = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedResponse == "[]" || 
                           trimmedResponse.contains("\"collection\":[]") ||
                           trimmedResponse.contains("\"count\":0") {
                            print("✅ [NotificationsManager] Server returned empty notifications - this is normal")
                            self.notifications = []
                            self.unreadNotificationsCount = 0
                            return
                        }
                    }
                    
                    print("❌ [NotificationsManager] Failed to decode notifications response - invalid format")
                    let fallbackNotification = NotificationItem(
                        title: "System",
                        message: "Failed to load notifications from server. Using fallback data.",
                        date: Date(),
                        createdAt: Date(),
                        isRead: false,
                        url: nil,
                        apiId: nil,
                        type: "error"
                    )
                    self.notifications = [fallbackNotification]
                    self.unreadNotificationsCount = 1
                }
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    
    private func processNotificationsArray(_ apiNotifications: [APINotification]) {
        var newNotifications: [NotificationItem] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for apiNotif in apiNotifications {
            var createdDate: Date?
            
            if let createdAtString = apiNotif.created_at {
                createdDate = dateFormatter.date(from: createdAtString)
            }
            
            if createdDate == nil && !(apiNotif.created_at?.isEmpty ?? true) {
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                createdDate = fallbackFormatter.date(from: apiNotif.created_at ?? "")
            }
            
            let notification = NotificationItem(
                title: apiNotif.title ?? "No Title",
                message: apiNotif.message ?? "No Message",
                date: createdDate,
                createdAt: createdDate,
                isRead: apiNotif.is_read ?? false,
                url: apiNotif.url,
                apiId: apiNotif.id,
                type: apiNotif.type
            )
            
            newNotifications.append(notification)
        }
        
        // Replace current notifications with fetched ones
        notifications = newNotifications
        // Update unread count from local data for direct array (fallback)
        unreadNotificationsCount = newNotifications.filter { !$0.isRead }.count
        
        print("Successfully fetched \(newNotifications.count) notifications (direct array)")
    }
    
    private func processNotificationsResponse(_ response: NotificationsResponse) {
        var newNotifications: [NotificationItem] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for apiNotif in response.collection {
            var createdDate: Date?
            
            if let createdAtString = apiNotif.created_at {
                createdDate = dateFormatter.date(from: createdAtString)
            }
            
            if createdDate == nil && !(apiNotif.created_at?.isEmpty ?? true) {
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                createdDate = fallbackFormatter.date(from: apiNotif.created_at ?? "")
            }
            
            let notification = NotificationItem(
                title: apiNotif.title ?? "No Title",
                message: apiNotif.message ?? "No Message", 
                date: createdDate,
                createdAt: createdDate,
                isRead: apiNotif.is_read ?? false,
                url: apiNotif.url,
                apiId: apiNotif.id,
                type: apiNotif.type
            )
            
            newNotifications.append(notification)
        }
        
        // Replace current notifications with fetched ones
        notifications = newNotifications
        // Use unread count from API response
        unreadNotificationsCount = response.count_unread
        
        print("✅ Successfully fetched \(newNotifications.count) notifications, \(response.count_unread) unread, total count: \(response.count)")
    }
    
    private func createFallbackNotifications() {
        let fallbackNotifications = [
            NotificationItem(
                title: "Welcome to AllyHub",
                message: "Your task management companion is ready to help you stay organized and productive.",
                date: Date().addingTimeInterval(-3600),
                createdAt: Date().addingTimeInterval(-3600),
                isRead: false,
                url: nil,
                apiId: nil,
                type: "info"
            ),
            NotificationItem(
                title: "Timer Started", 
                message: "Your focus session has begun. Stay concentrated and make progress on your current task.",
                date: Date().addingTimeInterval(-1800),
                createdAt: Date().addingTimeInterval(-1800),
                isRead: true,
                url: nil,
                apiId: nil,
                type: "success"
            ),
            NotificationItem(
                title: "System Update",
                message: "AllyHub has been updated to the latest version with improved performance and new features.",
                date: Date().addingTimeInterval(-300),
                createdAt: Date().addingTimeInterval(-300),
                isRead: false,
                url: "https://example.com/update-notes",
                apiId: nil,
                type: "info"
            )
        ]
        
        notifications = fallbackNotifications
        unreadNotificationsCount = fallbackNotifications.filter { !$0.isRead }.count
        print("Using fallback notifications")
    }
}

// MARK: - API Response Models

struct NotificationsResponse: Codable {
    let collection: [APINotification]
    let count: Int
    let count_unread: Int
}

struct APINotification: Codable {
    let id: String?
    let url: String?
    let title: String?
    let message: String?
    let type: String?
    let is_read: Bool?
    let created_at: String?
}