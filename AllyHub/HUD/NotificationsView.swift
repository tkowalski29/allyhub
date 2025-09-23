import SwiftUI

struct NotificationsView: View {
    @Binding var notifications: [NotificationItem]
    @Binding var unreadNotificationsCount: Int
    @Binding var expandedNotificationId: UUID?
    @ObservedObject var communicationSettings: CommunicationSettings
    let onRefresh: () -> Void
    
    @State private var infoExpandedNotificationId: UUID?
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            notificationsList
        }
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                    notificationRow(notification: notification, index: index)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private func notificationRow(notification: NotificationItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Type icon on white circle background
                Image(systemName: notificationTypeIcon(for: notification))
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
                
                // Title only (message will be in expanded section)
                Text(notification.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                // Right side - status icon or hover actions
                HStack(spacing: 8) {
                    if expandedNotificationId == notification.id {
                        // Hover actions (4 buttons: status, delete, link, info)
                        notificationHoverActions(notification: notification, index: index)
                    } else {
                        // Normal state - show read/unread status icon
                        Image(systemName: notification.isRead ? "envelope" : "envelope.open")
                            .font(.system(size: 16))
                            .foregroundStyle(notification.isRead ? .white.opacity(0.3) : .white.opacity(0.8))
                    }
                }
            }
            
            // Expanded info section (message and date) - shown when info button is clicked
            if infoExpandedNotificationId == notification.id {
                VStack(alignment: .leading, spacing: 8) {
                    // Message
                    Text(notification.message)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    // Date
                    let displayDate = notification.createdAt ?? notification.date ?? Date()
                    Text("\(displayDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 4)
                .padding(.leading, 44) // Align with title (32px icon + 12px spacing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(notificationBackground(for: notification))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                if isHovering {
                    expandedNotificationId = notification.id
                } else {
                    expandedNotificationId = nil
                }
            }
        }
    }
    
    private func notificationHoverActions(notification: NotificationItem, index: Int) -> some View {
        HStack(spacing: 6) {
            // 1. Status toggle button (read/unread)
            Button(action: {
                toggleNotificationReadStatus(notification: notification, index: index)
            }) {
                Image(systemName: notification.isRead ? "envelope.open.fill" : "envelope.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(notification.isRead ? .blue : .gray)
                    .frame(width: 20, height: 20)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // 2. Delete button
            Button(action: {
                removeNotification(notification: notification, index: index)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .frame(width: 20, height: 20)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // 3. Link button - only show if URL exists
            if let url = notification.url, !url.isEmpty {
                Button(action: {
                    openURL(url)
                }) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                        .frame(width: 20, height: 20)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // 4. Info/expand button
            Button(action: {
                toggleInfoExpansion(notification.id)
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .frame(width: 20, height: 20)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func notificationBackground(for notification: NotificationItem) -> Color {
        notification.isRead ? Color.white.opacity(0.08) : Color.blue.opacity(0.15)
    }
    
    private func notificationTypeIcon(for notification: NotificationItem) -> String {
        // First check API type field if available
        if let type = notification.type?.lowercased() {
            switch type {
            case "info":
                return "info.circle"
            case "warning":
                return "exclamationmark.triangle"
            case "error":
                return "xmark.octagon"
            case "success":
                return "checkmark.seal"
            case "timer":
                return "timer"
            case "task":
                return "checkmark.circle"
            case "message":
                return "message"
            default:
                break
            }
        }
        
        // Fallback to analyzing title/message keywords
        let title = notification.title.lowercased()
        let message = notification.message.lowercased()
        
        if title.contains("timer") || title.contains("focus") || message.contains("timer") {
            return "timer"
        } else if title.contains("task") || title.contains("todo") || message.contains("task") {
            return "checkmark.circle"
        } else if title.contains("system") || title.contains("update") || message.contains("system") {
            return "gear"
        } else if title.contains("welcome") || title.contains("hello") || message.contains("welcome") {
            return "hand.wave"
        } else if title.contains("error") || title.contains("failed") || message.contains("error") {
            return "exclamationmark.triangle"
        } else if title.contains("success") || title.contains("completed") || message.contains("success") {
            return "checkmark.seal"
        } else if title.contains("message") || title.contains("chat") || message.contains("message") {
            return "message"
        } else {
            // Default notification icon
            return "bell"
        }
    }
    
    private func removeNotification(notification: NotificationItem, index: Int) {
        // Update unread count if removing unread notification
        if !notification.isRead {
            unreadNotificationsCount = max(0, unreadNotificationsCount - 1)
        }
        
        // Remove from local list with animation
        let _ = withAnimation(.easeOut(duration: 0.2)) {
            notifications.remove(at: index)
        }
        
        // Send remove request to API if we have an API ID
        if let apiId = notification.apiId {
            print("🗑️ Removing notification \(apiId)")
            updateNotificationStatus(notificationId: apiId, isRead: nil, action: "remove")
        } else {
            print("❌ Cannot send remove update: notification has no apiId")
        }
    }
    
    private func toggleNotificationExpansion(_ notificationId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedNotificationId == notificationId {
                expandedNotificationId = nil
            } else {
                expandedNotificationId = notificationId
            }
        }
    }
    
    private func toggleInfoExpansion(_ notificationId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if infoExpandedNotificationId == notificationId {
                infoExpandedNotificationId = nil
            } else {
                infoExpandedNotificationId = notificationId
            }
        }
    }
    
    private func toggleNotificationReadStatus(notification: NotificationItem, index: Int) {
        // Toggle local read status
        let wasRead = notifications[index].isRead
        notifications[index].isRead.toggle()
        
        // Update unread count
        if wasRead {
            // Was read, now unread - increase count
            unreadNotificationsCount += 1
        } else {
            // Was unread, now read - decrease count
            unreadNotificationsCount = max(0, unreadNotificationsCount - 1)
        }
        
        // Send update to API if we have an API ID
        if let apiId = notification.apiId {
            let newStatus = notifications[index].isRead
            print("🔄 Toggling notification \(apiId): \(wasRead ? "read" : "unread") -> \(newStatus ? "read" : "unread")")
            updateNotificationStatus(notificationId: apiId, isRead: newStatus)
        } else {
            print("❌ Cannot send read/unread update: notification has no apiId")
        }
    }
    
    private func updateNotificationStatus(notificationId: String, isRead: Bool?, action: String? = nil) {
        guard !communicationSettings.notificationUpdateURL.isEmpty else {
            print("❌ Notification status URL is empty - configure in Settings")
            return
        }
        
        guard let url = URL(string: communicationSettings.notificationUpdateURL) else {
            print("Invalid notification status URL: \(communicationSettings.notificationUpdateURL)")
            return
        }
        
        let actionValue: String
        if let customAction = action {
            actionValue = customAction
        } else if let isRead = isRead {
            // Direct logic: send the action that the hover icon represents
            actionValue = isRead ? "read" : "unread"
        } else {
            actionValue = "remove" // Default fallback
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        print("🚀 Sending API request to: \(url)")
        print("📤 Request body: id=\(notificationId), action=\(actionValue), timestamp=\(timestamp)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "id": notificationId,
            "action": actionValue,
            "timestamp": timestamp
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to serialize notification status request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification status update error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Notification status update response: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        print("Successfully updated notification \(notificationId) to \(actionValue)")
                    }
                }
            }
        }.resume()
    }
    
    private func handleRefresh() {
        // Start refresh animation
        isRefreshing = true
        
        // Call the refresh callback
        onRefresh()
        
        // Stop animation after a delay (simulate network request time)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRefreshing = false
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - NotificationItem
struct NotificationItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var message: String
    var date: Date?
    var createdAt: Date?
    var isRead: Bool
    var url: String?
    var apiId: String?
    var type: String?
    
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.message == rhs.message &&
               lhs.isRead == rhs.isRead
    }
}