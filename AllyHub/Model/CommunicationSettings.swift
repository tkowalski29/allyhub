import SwiftUI

@MainActor
final class CommunicationSettings: ObservableObject {
    @Published var tasksFetchURL: String = ""
    @Published var taskUpdateURL: String = ""
    @Published var chatHistoryURL: String = ""
    @Published var chatStreamURL: String = ""
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
        notificationsFetchURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationsFetchURL") ?? ""
        notificationStatusURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationStatusURL") ?? ""
    }
    
    func saveSettings() {
        UserDefaults.standard.set(tasksFetchURL, forKey: "AllyHub.TasksFetchURL")
        UserDefaults.standard.set(taskUpdateURL, forKey: "AllyHub.TaskUpdateURL")
        UserDefaults.standard.set(chatHistoryURL, forKey: "AllyHub.ChatHistoryURL")
        UserDefaults.standard.set(chatStreamURL, forKey: "AllyHub.ChatStreamURL")
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