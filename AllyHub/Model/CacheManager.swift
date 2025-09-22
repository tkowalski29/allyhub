import Foundation

@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    // MARK: - Cache Keys
    private enum CacheKey: String {
        case conversations = "AllyHub.Cache.Conversations"
        case currentConversationHistory = "AllyHub.Cache.ConversationHistory"
        case tasks = "AllyHub.Cache.Tasks"
        case notifications = "AllyHub.Cache.Notifications"
        case actions = "AllyHub.Cache.Actions"
        case refreshSettings = "AllyHub.Cache.RefreshSettings"
    }
    
    // MARK: - Published Properties
    @Published var cachedConversations: [ChatService.Conversation] = []
    @Published var cachedConversationHistory: [ChatService.ChatMessage] = []
    @Published var cachedTasks: [CacheManager.CachedTask] = []
    @Published var cachedNotifications: [APINotification] = []
    @Published var cachedActions: [APIAction] = []
    
    // MARK: - Cache Timestamps
    private var conversationsLastFetch: Date?
    private var conversationHistoryLastFetch: Date?
    private var tasksLastFetch: Date?
    private var notificationsLastFetch: Date?
    private var actionsLastFetch: Date?
    
    // MARK: - Refresh Settings
    @Published var tasksRefreshInterval: TimeInterval = 600 // 10 minutes default
    @Published var notificationsRefreshInterval: TimeInterval = 600 // 10 minutes default
    
    // MARK: - Background Timers
    private var tasksRefreshTimer: Timer?
    private var notificationsRefreshTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        loadCachedData()
        loadRefreshSettings()
        startBackgroundRefresh()
    }
    
    // MARK: - Cache Operations
    
    // MARK: Conversations
    func cacheConversations(_ conversations: [ChatService.Conversation]) {
        cachedConversations = conversations
        conversationsLastFetch = Date()
        saveToDisk(conversations, key: .conversations)
    }
    
    func getCachedConversations(maxAge: TimeInterval = 300) -> [ChatService.Conversation]? {
        guard let lastFetch = conversationsLastFetch,
              Date().timeIntervalSince(lastFetch) < maxAge else {
            return nil
        }
        return cachedConversations.isEmpty ? nil : cachedConversations
    }
    
    // MARK: Conversation History
    func cacheConversationHistory(_ messages: [ChatService.ChatMessage], conversationId: String) {
        cachedConversationHistory = messages
        conversationHistoryLastFetch = Date()
        saveToDisk(messages, key: .currentConversationHistory)
    }
    
    func getCachedConversationHistory(maxAge: TimeInterval = 300) -> [ChatService.ChatMessage]? {
        guard let lastFetch = conversationHistoryLastFetch,
              Date().timeIntervalSince(lastFetch) < maxAge else {
            return nil
        }
        return cachedConversationHistory.isEmpty ? nil : cachedConversationHistory
    }
    
    // MARK: Tasks
    func cacheTasks(_ tasks: [CacheManager.CachedTask]) {
        cachedTasks = tasks
        tasksLastFetch = Date()
        saveToDisk(tasks, key: .tasks)
    }
    
    func getCachedTasks(maxAge: TimeInterval? = nil) -> [CacheManager.CachedTask]? {
        let maxAge = maxAge ?? tasksRefreshInterval
        guard let lastFetch = tasksLastFetch,
              Date().timeIntervalSince(lastFetch) < maxAge else {
            return nil
        }
        return cachedTasks.isEmpty ? nil : cachedTasks
    }
    
    // MARK: Notifications
    func cacheNotifications(_ notifications: [APINotification]) {
        cachedNotifications = notifications
        notificationsLastFetch = Date()
        saveToDisk(notifications, key: .notifications)
    }
    
    func getCachedNotifications(maxAge: TimeInterval? = nil) -> [APINotification]? {
        let maxAge = maxAge ?? notificationsRefreshInterval
        guard let lastFetch = notificationsLastFetch,
              Date().timeIntervalSince(lastFetch) < maxAge else {
            return nil
        }
        return cachedNotifications.isEmpty ? nil : cachedNotifications
    }
    
    // MARK: Actions
    func cacheActions(_ actions: [APIAction]) {
        cachedActions = actions
        actionsLastFetch = Date()
        saveToDisk(actions, key: .actions)
    }
    
    func getCachedActions(maxAge: TimeInterval = 3600) -> [APIAction]? { // 1 hour default
        guard let lastFetch = actionsLastFetch,
              Date().timeIntervalSince(lastFetch) < maxAge else {
            return nil
        }
        return cachedActions.isEmpty ? nil : cachedActions
    }
    
    // MARK: - Background Refresh
    func updateRefreshIntervals(tasks: TimeInterval, notifications: TimeInterval) {
        tasksRefreshInterval = tasks
        notificationsRefreshInterval = notifications
        saveRefreshSettings()
        restartBackgroundRefresh()
    }
    
    private func startBackgroundRefresh() {
        startTasksRefreshTimer()
        startNotificationsRefreshTimer()
    }
    
    private func restartBackgroundRefresh() {
        stopBackgroundRefresh()
        startBackgroundRefresh()
    }
    
    private func stopBackgroundRefresh() {
        tasksRefreshTimer?.invalidate()
        notificationsRefreshTimer?.invalidate()
    }
    
    private func startTasksRefreshTimer() {
        tasksRefreshTimer?.invalidate()
        tasksRefreshTimer = Timer.scheduledTimer(withTimeInterval: tasksRefreshInterval, repeats: true) { _ in
            Task { @MainActor in
                self.refreshTasksInBackground()
            }
        }
    }
    
    private func startNotificationsRefreshTimer() {
        notificationsRefreshTimer?.invalidate()
        notificationsRefreshTimer = Timer.scheduledTimer(withTimeInterval: notificationsRefreshInterval, repeats: true) { _ in
            Task { @MainActor in
                self.refreshNotificationsInBackground()
            }
        }
    }
    
    // MARK: Background refresh handlers (to be called by managers)
    private func refreshTasksInBackground() {
        // This will be called by TasksManager
        NotificationCenter.default.post(name: .refreshTasksInBackground, object: nil)
    }
    
    private func refreshNotificationsInBackground() {
        // This will be called by NotificationsManager
        NotificationCenter.default.post(name: .refreshNotificationsInBackground, object: nil)
    }
    
    // MARK: - Persistence
    private func saveToDisk<T: Codable>(_ data: T, key: CacheKey) {
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: key.rawValue)
        } catch {
            print("Failed to cache \(key.rawValue): \(error)")
        }
    }
    
    private func loadFromDisk<T: Codable>(_ type: T.Type, key: CacheKey) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load cached \(key.rawValue): \(error)")
            return nil
        }
    }
    
    private func loadCachedData() {
        cachedConversations = loadFromDisk([ChatService.Conversation].self, key: .conversations) ?? []
        cachedConversationHistory = loadFromDisk([ChatService.ChatMessage].self, key: .currentConversationHistory) ?? []
        cachedTasks = loadFromDisk([CacheManager.CachedTask].self, key: .tasks) ?? []
        cachedNotifications = loadFromDisk([APINotification].self, key: .notifications) ?? []
        cachedActions = loadFromDisk([APIAction].self, key: .actions) ?? []
    }
    
    private func saveRefreshSettings() {
        let settings = RefreshSettings(
            tasksInterval: tasksRefreshInterval,
            notificationsInterval: notificationsRefreshInterval
        )
        saveToDisk(settings, key: .refreshSettings)
    }
    
    private func loadRefreshSettings() {
        if let settings = loadFromDisk(RefreshSettings.self, key: .refreshSettings) {
            tasksRefreshInterval = settings.tasksInterval
            notificationsRefreshInterval = settings.notificationsInterval
        }
    }
    
    // MARK: - Clear Cache
    func clearConversationHistoryCache() {
        cachedConversationHistory.removeAll()
        conversationHistoryLastFetch = nil
        UserDefaults.standard.removeObject(forKey: CacheKey.currentConversationHistory.rawValue)
    }

    func clearAllCache() {
        cachedConversations.removeAll()
        cachedConversationHistory.removeAll()
        cachedTasks.removeAll()
        cachedNotifications.removeAll()
        cachedActions.removeAll()
        
        conversationsLastFetch = nil
        conversationHistoryLastFetch = nil
        tasksLastFetch = nil
        notificationsLastFetch = nil
        actionsLastFetch = nil
        
        // Clear from disk
        UserDefaults.standard.removeObject(forKey: CacheKey.conversations.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.currentConversationHistory.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.tasks.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.notifications.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.actions.rawValue)
    }
}

// MARK: - Supporting Types
struct RefreshSettings: Codable {
    let tasksInterval: TimeInterval
    let notificationsInterval: TimeInterval
}

// MARK: - Cacheable Task Structure
extension CacheManager {
    struct CachedTask: Codable {
        let id: String
        let title: String
        let description: String
        let status: String
        let priority: String // Store as string for Codable compatibility
        let assignedTo: String?
        let dueDate: Date?
        let createdAt: Date?
        let updatedAt: Date?
        let isCompleted: Bool
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let refreshTasksInBackground = Notification.Name("refreshTasksInBackground")
    static let refreshNotificationsInBackground = Notification.Name("refreshNotificationsInBackground")
}