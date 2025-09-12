import SwiftUI

@MainActor
final class CommunicationSettings: ObservableObject {
    @Published var tasksFetchURL: String = ""
    @Published var taskUpdateURL: String = ""
    @Published var chatHistoryURL: String = ""
    @Published var chatStreamURL: String = ""
    @Published var chatEnableStream: Bool = false
    @Published var chatMessageURL: String = ""
    @Published var chatCollectionURL: String = ""
    @Published var notificationCollectionURL: String = ""
    @Published var notificationActionURL: String = ""
    @Published var notificationsFetchURL: String = ""
    @Published var notificationStatusURL: String = ""
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        tasksFetchURL = UserDefaults.standard.string(forKey: "AllyHub.TasksFetchURL") ?? ""
        taskUpdateURL = UserDefaults.standard.string(forKey: "AllyHub.TaskUpdateURL") ?? ""
        chatHistoryURL = UserDefaults.standard.string(forKey: "AllyHub.ChatHistoryURL") ?? ""
        chatStreamURL = UserDefaults.standard.string(forKey: "AllyHub.ChatStreamURL") ?? ""
        chatEnableStream = UserDefaults.standard.bool(forKey: "AllyHub.ChatEnableStream")
        chatMessageURL = UserDefaults.standard.string(forKey: "AllyHub.ChatMessageURL") ?? ""
        chatCollectionURL = UserDefaults.standard.string(forKey: "AllyHub.ChatCollectionURL") ?? ""
        notificationCollectionURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationCollectionURL") ?? ""
        notificationActionURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationActionURL") ?? ""
        notificationsFetchURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationsFetchURL") ?? ""
        notificationStatusURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationStatusURL") ?? ""
    }
    
    func saveSettings() {
        UserDefaults.standard.set(tasksFetchURL, forKey: "AllyHub.TasksFetchURL")
        UserDefaults.standard.set(taskUpdateURL, forKey: "AllyHub.TaskUpdateURL")
        UserDefaults.standard.set(chatHistoryURL, forKey: "AllyHub.ChatHistoryURL")
        UserDefaults.standard.set(chatStreamURL, forKey: "AllyHub.ChatStreamURL")
        UserDefaults.standard.set(chatEnableStream, forKey: "AllyHub.ChatEnableStream")
        UserDefaults.standard.set(chatMessageURL, forKey: "AllyHub.ChatMessageURL")
        UserDefaults.standard.set(chatCollectionURL, forKey: "AllyHub.ChatCollectionURL")
        UserDefaults.standard.set(notificationCollectionURL, forKey: "AllyHub.NotificationCollectionURL")
        UserDefaults.standard.set(notificationActionURL, forKey: "AllyHub.NotificationActionURL")
        UserDefaults.standard.set(notificationsFetchURL, forKey: "AllyHub.NotificationsFetchURL")
        UserDefaults.standard.set(notificationStatusURL, forKey: "AllyHub.NotificationStatusURL")
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
}