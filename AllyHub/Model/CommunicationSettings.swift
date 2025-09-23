import SwiftUI

@MainActor
final class CommunicationSettings: ObservableObject {
    // AllyHub Center configuration
    @Published var useAllyHubCenter: Bool = false
    @Published var allyHubCenterURL: String = ""
    @Published var allyHubCenterToken: String = ""
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var isTestingConnection: Bool = false
    @Published var debugModeEnabled: Bool = true

    // Manual endpoint configuration
    @Published var taskFetchURL: String = ""        // task_fetch
    @Published var taskUpdateURL: String = ""       // task_update
    @Published var taskCreateURL: String = ""       // task_create
    @Published var chatOneURL: String = ""          // chat_one (history)
    @Published var chatStreamURL: String = ""
    @Published var chatEnableStream: Bool = false
    @Published var chatMessageURL: String = ""      // chat_message
    @Published var chatCollectionURL: String = ""
    @Published var chatFetchURL: String = ""        // chat_fetch (get conversation)
    @Published var chatCreateURL: String = ""       // chat_create (create conversation)
    @Published var notificationFetchURL: String = "" // notification_fetch
    @Published var notificationUpdateURL: String = "" // notification_update
    @Published var notificationsRefreshInterval: Int = 10 // minutes
    @Published var tasksRefreshInterval: Int = 10 // minutes
    @Published var actionFetchURL: String = ""      // action_fetch
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // AllyHub Center settings
        useAllyHubCenter = UserDefaults.standard.bool(forKey: "AllyHub.UseAllyHubCenter")
        allyHubCenterURL = UserDefaults.standard.string(forKey: "AllyHub.AllyHubCenterURL") ?? "http://127.0.0.1:3030"
        allyHubCenterToken = UserDefaults.standard.string(forKey: "AllyHub.AllyHubCenterToken") ?? ""
        debugModeEnabled = UserDefaults.standard.bool(forKey: "AllyHub.DebugModeEnabled")

        // Manual endpoint settings
        taskFetchURL = UserDefaults.standard.string(forKey: "AllyHub.TaskFetchURL") ?? ""
        taskUpdateURL = UserDefaults.standard.string(forKey: "AllyHub.TaskUpdateURL") ?? ""
        taskCreateURL = UserDefaults.standard.string(forKey: "AllyHub.TaskCreateURL") ?? ""
        chatOneURL = UserDefaults.standard.string(forKey: "AllyHub.ChatOneURL") ?? ""
        chatStreamURL = UserDefaults.standard.string(forKey: "AllyHub.ChatStreamURL") ?? ""
        chatEnableStream = UserDefaults.standard.bool(forKey: "AllyHub.ChatEnableStream")
        chatMessageURL = UserDefaults.standard.string(forKey: "AllyHub.ChatMessageURL") ?? ""
        chatCollectionURL = UserDefaults.standard.string(forKey: "AllyHub.ChatCollectionURL") ?? ""
        chatFetchURL = UserDefaults.standard.string(forKey: "AllyHub.ChatFetchURL") ?? ""
        chatCreateURL = UserDefaults.standard.string(forKey: "AllyHub.ChatCreateURL") ?? ""
        notificationFetchURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationFetchURL") ?? ""
        notificationUpdateURL = UserDefaults.standard.string(forKey: "AllyHub.NotificationUpdateURL") ?? ""
        notificationsRefreshInterval = UserDefaults.standard.object(forKey: "AllyHub.NotificationsRefreshInterval") as? Int ?? 10
        tasksRefreshInterval = UserDefaults.standard.object(forKey: "AllyHub.TasksRefreshInterval") as? Int ?? 10
        actionFetchURL = UserDefaults.standard.string(forKey: "AllyHub.ActionFetchURL") ?? ""

        // Load endpoints from AllyHub Center if enabled
        if useAllyHubCenter {
            loadEndpointsFromAllyHubCenter()
        }
    }
    
    func saveSettings() {
        // Save AllyHub Center settings
        UserDefaults.standard.set(useAllyHubCenter, forKey: "AllyHub.UseAllyHubCenter")
        UserDefaults.standard.set(allyHubCenterURL, forKey: "AllyHub.AllyHubCenterURL")
        UserDefaults.standard.set(allyHubCenterToken, forKey: "AllyHub.AllyHubCenterToken")
        UserDefaults.standard.set(debugModeEnabled, forKey: "AllyHub.DebugModeEnabled")

        // Save manual endpoint settings
        UserDefaults.standard.set(taskFetchURL, forKey: "AllyHub.TaskFetchURL")
        UserDefaults.standard.set(taskUpdateURL, forKey: "AllyHub.TaskUpdateURL")
        UserDefaults.standard.set(taskCreateURL, forKey: "AllyHub.TaskCreateURL")
        UserDefaults.standard.set(chatOneURL, forKey: "AllyHub.ChatOneURL")
        UserDefaults.standard.set(chatStreamURL, forKey: "AllyHub.ChatStreamURL")
        UserDefaults.standard.set(chatEnableStream, forKey: "AllyHub.ChatEnableStream")
        UserDefaults.standard.set(chatMessageURL, forKey: "AllyHub.ChatMessageURL")
        UserDefaults.standard.set(chatCollectionURL, forKey: "AllyHub.ChatCollectionURL")
        UserDefaults.standard.set(chatFetchURL, forKey: "AllyHub.ChatFetchURL")
        UserDefaults.standard.set(chatCreateURL, forKey: "AllyHub.ChatCreateURL")
        UserDefaults.standard.set(notificationFetchURL, forKey: "AllyHub.NotificationFetchURL")
        UserDefaults.standard.set(notificationUpdateURL, forKey: "AllyHub.NotificationUpdateURL")
        UserDefaults.standard.set(notificationsRefreshInterval, forKey: "AllyHub.NotificationsRefreshInterval")
        UserDefaults.standard.set(tasksRefreshInterval, forKey: "AllyHub.TasksRefreshInterval")
        UserDefaults.standard.set(actionFetchURL, forKey: "AllyHub.ActionFetchURL")
    }
    
    func updateTaskFetchURL(_ url: String) {
        taskFetchURL = url
        saveSettings()
    }

    func updateTaskUpdateURL(_ url: String) {
        taskUpdateURL = url
        saveSettings()
    }

    func updateChatOneURL(_ url: String) {
        chatOneURL = url
        saveSettings()
    }

    func updateChatStreamURL(_ url: String) {
        chatStreamURL = url
        saveSettings()
    }

    func updateNotificationFetchURL(_ url: String) {
        notificationFetchURL = url
        saveSettings()
    }

    func updateNotificationUpdateURL(_ url: String) {
        notificationUpdateURL = url
        saveSettings()
    }

    func updateActionFetchURL(_ url: String) {
        actionFetchURL = url
        saveSettings()
    }

    func updateChatFetchURL(_ url: String) {
        chatFetchURL = url
        saveSettings()
    }
    
    func updateChatCreateURL(_ url: String) {
        chatCreateURL = url
        saveSettings()
    }
    
    func updateChatMessageURL(_ url: String) {
        chatMessageURL = url
        saveSettings()
    }

    // MARK: - AllyHub Center Integration

    func setAllyHubCenterMode(_ enabled: Bool) {
        useAllyHubCenter = enabled
        if enabled {
            // Set fixed URL for AllyHub Center
            allyHubCenterURL = "http://127.0.0.1:3030"
            loadEndpointsFromAllyHubCenter()
        } else {
            clearAllEndpoints()
        }
        saveSettings()
    }

    func updateAllyHubCenterURL(_ url: String) {
        allyHubCenterURL = url
        if useAllyHubCenter {
            loadEndpointsFromAllyHubCenter()
        }
        saveSettings()
    }

    func updateAllyHubCenterToken(_ token: String) {
        allyHubCenterToken = token
        if useAllyHubCenter {
            loadEndpointsFromAllyHubCenter()
        }
        saveSettings()
    }

    private func loadEndpointsFromAllyHubCenter() {
        guard !allyHubCenterURL.isEmpty, !allyHubCenterToken.isEmpty else {
            print("⚠️ AllyHub Center URL or token is empty")
            return
        }

        let baseURL = allyHubCenterURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/api/pool") else {
            print("❌ Invalid AllyHub Center URL: \(baseURL)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(allyHubCenterToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0

        // Add empty JSON body for POST request
        let requestBody = "{}"
        request.httpBody = requestBody.data(using: .utf8)

        print("🔍 Fetching pool from AllyHub Center: \(url)")
        print("🔍 Using token: \(allyHubCenterToken.prefix(20))...")
        print("🔍 Authorization header: Bearer \(allyHubCenterToken.prefix(20))...")
        print("🔍 Request method: \(request.httpMethod ?? "GET")")

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Pool API Response: \(httpResponse.statusCode)")

                    // Log response headers
                    for (key, value) in httpResponse.allHeaderFields {
                        print("📡 Header: \(key) = \(value)")
                    }

                    if httpResponse.statusCode != 200 {
                        print("❌ Pool API failed with status: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("❌ Error response body: \(responseString)")
                        }

                        // Handle specific HTTP status codes
                        if httpResponse.statusCode == 302 {
                            if let location = httpResponse.allHeaderFields["Location"] as? String {
                                print("❌ Redirect to: \(location)")
                                print("❌ This suggests authentication failure - check token validity")
                            }
                        }
                        return
                    }
                }

                // Log raw response data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API response: \(responseString)")
                } else {
                    print("❌ Could not decode response as UTF-8")
                }

                let poolResponse = try JSONDecoder().decode(PoolResponse.self, from: data)
                print("✅ Successfully parsed JSON response")
                print("✅ Pool name: \(poolResponse.data.name)")
                print("✅ Pool type: \(poolResponse.data.type)")
                print("✅ Found \(poolResponse.data.endpoints.count) endpoints")

                await MainActor.run {
                    self.mapPoolToEndpoints(poolResponse.data.endpoints)
                    self.saveSettings()
                    print("✅ AllyHub Center pool loaded and saved successfully")
                }

            } catch {
                await MainActor.run {
                    print("❌ Failed to load pool from AllyHub Center: \(error.localizedDescription)")
                }
            }
        }
    }

    private func mapPoolToEndpoints(_ endpoints: [String: PoolEndpoint]) {
        print("🔗 Starting to map \(endpoints.count) endpoints from pool")

        // Clear existing endpoints first
        clearAllEndpoints()

        // Map pool endpoints to application fields
        for (endpointName, endpoint) in endpoints {
            print("🔗 Processing endpoint: \(endpointName) -> \(endpoint.url)")

            switch endpointName {
            case "task_fetch":
                taskFetchURL = endpoint.url
                print("✅ Mapped task_fetch to: \(taskFetchURL)")
            case "task_update":
                taskUpdateURL = endpoint.url
                print("✅ Mapped task_update to: \(taskUpdateURL)")
            case "task_create":
                taskCreateURL = endpoint.url
                print("✅ Mapped task_create to: \(taskCreateURL)")
            case "chat_one":
                chatOneURL = endpoint.url
                print("✅ Mapped chat_one to: \(chatOneURL)")
            case "chat_message":
                chatMessageURL = endpoint.url
                print("✅ Mapped chat_message to: \(chatMessageURL)")
            case "chat_fetch":
                chatFetchURL = endpoint.url
                print("✅ Mapped chat_fetch to: \(chatFetchURL)")
            case "chat_create":
                chatCreateURL = endpoint.url
                print("✅ Mapped chat_create to: \(chatCreateURL)")
            case "notification_fetch":
                notificationFetchURL = endpoint.url
                print("✅ Mapped notification_fetch to: \(notificationFetchURL)")
            case "notification_update":
                notificationUpdateURL = endpoint.url
                print("✅ Mapped notification_update to: \(notificationUpdateURL)")
            case "action_fetch":
                actionFetchURL = endpoint.url
                print("✅ Mapped action_fetch to: \(actionFetchURL)")
            default:
                print("⚠️ Unknown pool endpoint: \(endpointName)")
            }
        }

        print("🔗 Finished mapping \(endpoints.count) endpoints from pool")
    }

    private func clearAllEndpoints() {
        // Clear all endpoint URLs when AllyHub Center mode is disabled
        taskFetchURL = ""
        taskUpdateURL = ""
        taskCreateURL = ""

        chatOneURL = ""
        chatMessageURL = ""
        chatFetchURL = ""
        chatCreateURL = ""
        chatStreamURL = ""
        chatCollectionURL = ""

        notificationFetchURL = ""
        notificationUpdateURL = ""

        actionFetchURL = ""

        print("🧹 All endpoint URLs cleared - AllyHub Center mode disabled")
    }

    func testConnection() {
        guard !allyHubCenterURL.isEmpty, !allyHubCenterToken.isEmpty else {
            connectionStatus = .failed
            return
        }

        isTestingConnection = true
        connectionStatus = .testing

        Task {
            do {
                let baseURL = allyHubCenterURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let url = URL(string: "\(baseURL)/api/health")!

                var request = URLRequest(url: url)
                request.setValue("Bearer \(allyHubCenterToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 10.0

                let (_, response) = try await URLSession.shared.data(for: request)

                await MainActor.run {
                    if let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200 {
                        connectionStatus = .success
                        print("✅ AllyHub Center connection test successful")
                    } else {
                        connectionStatus = .failed
                        print("❌ AllyHub Center connection test failed: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    }
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failed
                    isTestingConnection = false
                    print("❌ AllyHub Center connection test error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Pool API Models

struct PoolResponse: Codable {
    let success: Bool
    let message: String
    let data: PoolData
}

struct PoolData: Codable {
    let id: String
    let user_id: String
    let name: String
    let description: String
    let type: String
    let endpoints: [String: PoolEndpoint]
    let created: String
    let updated: String
    let is_default: Bool
}

struct PoolEndpoint: Codable {
    let url: String
    let method: String
    let description: String
}

enum ConnectionStatus {
    case unknown
    case testing
    case success
    case failed

    var color: Color {
        switch self {
        case .unknown:
            return Color.gray
        case .testing:
            return Color.blue
        case .success:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    var icon: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .testing:
            return "clock.circle"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}