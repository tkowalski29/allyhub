import SwiftUI

@MainActor
final class CommunicationSettings: ObservableObject {
    @Published var tasksFetchURL: String = ""
    @Published var taskUpdateURL: String = ""
    @Published var taskCreateURL: String = ""
    @Published var chatHistoryURL: String = "" // Collection endpoint - lista konwersacji
    @Published var chatStreamURL: String = ""
    @Published var chatEnableStream: Bool = false
    @Published var chatMessageURL: String = "" // Message endpoint - wysyłanie wiadomości
    @Published var chatCollectionURL: String = ""
    @Published var chatGetConversationURL: String = "" // Get endpoint - wiadomości w konwersacji
    @Published var chatCreateConversationURL: String = "" // Create endpoint - nowa konwersacja
    @Published var notificationsFetchURL: String = ""
    @Published var notificationStatusURL: String = ""
    @Published var notificationsRefreshInterval: Int = 10 // minutes
    @Published var actionsFetchURL: String = ""
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        tasksFetchURL = UserDefaults.standard.string(forKey: "AllyHub.TasksFetchURL") ?? ""
        taskUpdateURL = UserDefaults.standard.string(forKey: "AllyHub.TaskUpdateURL") ?? ""
        taskCreateURL = UserDefaults.standard.string(forKey: "AllyHub.TaskCreateURL") ?? ""
        chatHistoryURL = UserDefaults.standard.string(forKey: "AllyHub.ChatHistoryURL") ?? ""
        chatStreamURL = UserDefaults.standard.string(forKey: "AllyHub.ChatStreamURL") ?? ""
        chatEnableStream = UserDefaults.standard.bool(forKey: "AllyHub.ChatEnableStream")
        chatMessageURL = UserDefaults.standard.string(forKey: "AllyHub.ChatMessageURL") ?? ""
        chatCollectionURL = UserDefaults.standard.string(forKey: "AllyHub.ChatCollectionURL") ?? ""
        chatGetConversationURL = UserDefaults.standard.string(forKey: "AllyHub.ChatGetConversationURL") ?? ""
        chatCreateConversationURL = UserDefaults.standard.string(forKey: "AllyHub.ChatCreateConversationURL") ?? ""
        notificationsFetchURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationsFetchURL") ?? ""
        notificationStatusURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationStatusURL") ?? ""
        notificationsRefreshInterval = UserDefaults.standard.object(forKey: "AllyHub.NotificationsRefreshInterval") as? Int ?? 10
        actionsFetchURL = UserDefaults.standard.string(forKey: "AllyHub.ActionsFetchURL") ?? ""
    }
    
    func saveSettings() {
        UserDefaults.standard.set(tasksFetchURL, forKey: "AllyHub.TasksFetchURL")
        UserDefaults.standard.set(taskUpdateURL, forKey: "AllyHub.TaskUpdateURL")
        UserDefaults.standard.set(taskCreateURL, forKey: "AllyHub.TaskCreateURL")
        UserDefaults.standard.set(chatHistoryURL, forKey: "AllyHub.ChatHistoryURL")
        UserDefaults.standard.set(chatStreamURL, forKey: "AllyHub.ChatStreamURL")
        UserDefaults.standard.set(chatEnableStream, forKey: "AllyHub.ChatEnableStream")
        UserDefaults.standard.set(chatMessageURL, forKey: "AllyHub.ChatMessageURL")
        UserDefaults.standard.set(chatCollectionURL, forKey: "AllyHub.ChatCollectionURL")
        UserDefaults.standard.set(chatGetConversationURL, forKey: "AllyHub.ChatGetConversationURL")
        UserDefaults.standard.set(chatCreateConversationURL, forKey: "AllyHub.ChatCreateConversationURL")
        UserDefaults.standard.set(notificationsFetchURL, forKey: "AllyHub.NotificationsFetchURL")
        UserDefaults.standard.set(notificationStatusURL, forKey: "AllyHub.NotificationStatusURL")
        UserDefaults.standard.set(notificationsRefreshInterval, forKey: "AllyHub.NotificationsRefreshInterval")
        UserDefaults.standard.set(actionsFetchURL, forKey: "AllyHub.ActionsFetchURL")
    }
    
    func updateTasksFetchURL(_ url: String) {
        tasksFetchURL = url
        saveSettings()
    }
    
    func updateTaskUpdateURL(_ url: String) {
        taskUpdateURL = url
        saveSettings()
    }
    
    func updateChatHistoryURL(_ url: String) {
        chatHistoryURL = url
        saveSettings()
    }
    
    func updateChatStreamURL(_ url: String) {
        chatStreamURL = url
        saveSettings()
    }
    
    func updateNotificationsFetchURL(_ url: String) {
        notificationsFetchURL = url
        saveSettings()
    }
    
    func updateNotificationStatusURL(_ url: String) {
        notificationStatusURL = url
        saveSettings()
    }
    
    func updateActionsFetchURL(_ url: String) {
        actionsFetchURL = url
        saveSettings()
    }
    
    func updateChatGetConversationURL(_ url: String) {
        chatGetConversationURL = url
        saveSettings()
    }
    
    func updateChatCreateConversationURL(_ url: String) {
        chatCreateConversationURL = url
        saveSettings()
    }
    
    func updateChatMessageURL(_ url: String) {
        chatMessageURL = url
        saveSettings()
    }
}