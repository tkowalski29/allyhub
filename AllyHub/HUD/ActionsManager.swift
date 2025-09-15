import SwiftUI
import Foundation

@MainActor
class ActionsManager: ObservableObject {
    @Published var actions: [ActionItem] = []
    @Published var executingActionId: String?
    @Published var actionResponse: ActionResponse?
    @Published var showResponse: Bool = false
    
    private let communicationSettings: CommunicationSettings
    private let cacheManager = CacheManager.shared
    
    init(communicationSettings: CommunicationSettings) {
        self.communicationSettings = communicationSettings
        loadCachedActions()
    }
    
    private func loadCachedActions() {
        if let cachedActions = cacheManager.getCachedActions() {
            let actionItems = cachedActions.map { apiAction in
                // Convert APIActionParameter to ActionParameter
                var convertedParameters: [String: ActionParameter] = [:]
                if let apiParameters = apiAction.parameters {
                    for (key, apiParam) in apiParameters {
                        convertedParameters[key] = ActionParameter(
                            type: apiParam.type,
                            placeholder: apiParam.placeholder,
                            options: apiParam.options,
                            order: apiParam.order ?? 0
                        )
                    }
                }
                
                return ActionItem(
                    id: apiAction.id ?? UUID().uuidString,
                    title: apiAction.title ?? "No Title",
                    message: apiAction.message ?? "",
                    url: apiAction.url,
                    method: apiAction.method ?? "POST",
                    parameters: convertedParameters
                )
            }
            self.actions = actionItems
            print("📱 [ActionsManager] Loaded \(actionItems.count) actions from cache")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchActions() {
        print("🔄 [ActionsManager] Starting fetchActions()")
        
        guard !communicationSettings.actionsFetchURL.isEmpty else {
            print("❌ [ActionsManager] Actions fetch URL is empty")
            createFallbackActions()
            return
        }
        
        print("🌐 [ActionsManager] Fetch URL: \(communicationSettings.actionsFetchURL)")
        
        guard let url = URL(string: communicationSettings.actionsFetchURL) else {
            print("❌ [ActionsManager] Invalid actions fetch URL: \(communicationSettings.actionsFetchURL)")
            createFallbackActions()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "userId": "default_user"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to serialize actions request: \(error)")
            return
        }
        
        print("🚀 [ActionsManager] Sending POST request to: \(url)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [ActionsManager] Fetch error: \(error.localizedDescription)")
                    self.createFallbackActions()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 [ActionsManager] HTTP Response: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        print("⚠️ [ActionsManager] Non-200 status code: \(httpResponse.statusCode)")
                        self.createFallbackActions()
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ [ActionsManager] No data received from API")
                    self.createFallbackActions()
                    return
                }
                
                print("📦 [ActionsManager] Received \(data.count) bytes of data")
                
                // Log the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [ActionsManager] Raw response: \(responseString.prefix(200))...")
                } else {
                    print("🔍 [ActionsManager] Unable to decode response as UTF-8 string")
                }
                
                do {
                    // Try to decode as array containing ActionsResponse
                    if let responseArray = try? JSONDecoder().decode([ActionsResponse].self, from: data),
                       let firstResponse = responseArray.first {
                        print("✅ [ActionsManager] Decoded as array of ActionsResponse")
                        self.processActionsResponse(firstResponse)
                    } else if let directResponse = try? JSONDecoder().decode(ActionsResponse.self, from: data) {
                        print("✅ [ActionsManager] Decoded as direct ActionsResponse")
                        self.processActionsResponse(directResponse)
                    } else {
                        // Fallback: try to decode as direct array of actions
                        print("✅ [ActionsManager] Decoded as direct array of actions")
                        let apiActions = try JSONDecoder().decode([APIAction].self, from: data)
                        self.processActionsArray(apiActions)
                    }
                } catch {
                    print("❌ [ActionsManager] Failed to decode actions response: \(error)")
                    self.createFallbackActions()
                }
            }
        }.resume()
    }
    
    func executeAction(_ action: ActionItem, parameters: [String: ActionParameterValue]) {
        guard let urlString = action.url, let url = URL(string: urlString) else {
            showActionResponse(ActionResponse(success: false, message: "Invalid action URL"))
            return
        }
        
        executingActionId = action.id
        
        var request = URLRequest(url: url)
        request.httpMethod = action.method
        
        // Check if we have any file parameters
        let hasFiles = parameters.values.contains { value in
            switch value {
            case .file:
                return true
            case .string:
                return false
            }
        }
        
        if hasFiles {
            // Use multipart/form-data for file uploads
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                
                switch value {
                case .string(let stringValue):
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                    body.append(stringValue.data(using: .utf8)!)
                    body.append("\r\n".data(using: .utf8)!)
                    
                case .file(let fileURL):
                    let fileName = fileURL.lastPathComponent
                    let mimeType = getMimeType(for: fileURL)
                    
                    body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                    
                    do {
                        let fileData = try Data(contentsOf: fileURL)
                        body.append(fileData)
                    } catch {
                        executingActionId = nil
                        showActionResponse(ActionResponse(success: false, message: "Failed to read file: \(error.localizedDescription)"))
                        return
                    }
                    
                    body.append("\r\n".data(using: .utf8)!)
                }
            }
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            
        } else {
            // Use JSON for string-only parameters
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var requestBody: [String: Any] = [:]
            for (key, value) in parameters {
                switch value {
                case .string(let stringValue):
                    requestBody[key] = stringValue
                case .file:
                    // This shouldn't happen in this branch
                    break
                }
            }
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                executingActionId = nil
                showActionResponse(ActionResponse(success: false, message: "Failed to encode parameters"))
                return
            }
        }
        
        print("🚀 [ActionsManager] Executing action: \(action.title)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.executingActionId = nil
                
                if let error = error {
                    self.showActionResponse(ActionResponse(success: false, message: "Network error: \(error.localizedDescription)"))
                    return
                }
                
                guard let data = data else {
                    self.showActionResponse(ActionResponse(success: false, message: "No response data"))
                    return
                }
                
                // Try to parse as JSON response first
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = jsonResponse["success"] as? Bool,
                   let message = jsonResponse["message"] as? String {
                    self.showActionResponse(ActionResponse(success: success, message: message))
                } else if let textResponse = String(data: data, encoding: .utf8) {
                    // Fallback to text response
                    self.showActionResponse(ActionResponse(success: true, message: textResponse))
                } else {
                    self.showActionResponse(ActionResponse(success: false, message: "Invalid response format"))
                }
            }
        }.resume()
    }
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "zip":
            return "application/zip"
        case "mp4":
            return "video/mp4"
        case "mp3":
            return "audio/mpeg"
        default:
            return "application/octet-stream"
        }
    }
    
    // MARK: - Private Methods
    
    private func processActionsArray(_ apiActions: [APIAction]) {
        var newActions: [ActionItem] = []
        
        for apiAction in apiActions {
            // Convert APIActionParameter to ActionParameter
            var convertedParameters: [String: ActionParameter] = [:]
            if let apiParameters = apiAction.parameters {
                for (key, apiParam) in apiParameters {
                    convertedParameters[key] = ActionParameter(
                        type: apiParam.type,
                        placeholder: apiParam.placeholder,
                        options: apiParam.options,
                        order: apiParam.order ?? 0
                    )
                }
            }
            
            let action = ActionItem(
                id: apiAction.id ?? UUID().uuidString,
                title: apiAction.title ?? "No Title",
                message: apiAction.message ?? "",
                url: apiAction.url,
                method: apiAction.method ?? "POST",
                parameters: convertedParameters
            )
            
            newActions.append(action)
        }
        
        actions = newActions
        
        // Cache the actions
        cacheManager.cacheActions(apiActions)
        
        print("✅ Successfully fetched \(newActions.count) actions (direct array)")
    }
    
    private func processActionsResponse(_ response: ActionsResponse) {
        var newActions: [ActionItem] = []
        
        for apiAction in response.collection {
            // Convert APIActionParameter to ActionParameter
            var convertedParameters: [String: ActionParameter] = [:]
            if let apiParameters = apiAction.parameters {
                for (key, apiParam) in apiParameters {
                    convertedParameters[key] = ActionParameter(
                        type: apiParam.type,
                        placeholder: apiParam.placeholder,
                        options: apiParam.options,
                        order: apiParam.order ?? 0
                    )
                }
            }
            
            let action = ActionItem(
                id: apiAction.id ?? UUID().uuidString,
                title: apiAction.title ?? "No Title",
                message: apiAction.message ?? "",
                url: apiAction.url,
                method: apiAction.method ?? "POST",
                parameters: convertedParameters
            )
            
            newActions.append(action)
        }
        
        actions = newActions
        
        // Cache the actions
        cacheManager.cacheActions(response.collection)
        
        print("✅ Successfully fetched \(newActions.count) actions, total count: \(response.count)")
    }
    
    private func createFallbackActions() {
        actions = []
        print("No actions available - API fetch failed")
    }
    
    private func showActionResponse(_ response: ActionResponse) {
        actionResponse = response
        showResponse = true
        
        // Auto-hide response after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showResponse = false
        }
    }
}

// MARK: - Data Models

struct ActionItem: Identifiable {
    let id: String
    let title: String
    let message: String
    let url: String?
    let method: String
    let parameters: [String: ActionParameter]
}

struct ActionParameter {
    let type: String // "string", "select", or "file"
    let placeholder: String
    let options: [String: String]? // For select type
    let order: Int // For ordering parameters
    
    init(type: String, placeholder: String, options: [String: String]? = nil, order: Int = 0) {
        self.type = type
        self.placeholder = placeholder
        self.options = options
        self.order = order
    }
}

struct ActionResponse {
    let success: Bool
    let message: String
}

enum ActionParameterValue {
    case string(String)
    case file(URL)
}

// MARK: - API Response Models

struct ActionsResponse: Codable {
    let collection: [APIAction]
    let count: Int
}

struct APIAction: Codable {
    let id: String?
    let url: String?
    let method: String?
    let title: String?
    let message: String?
    let parameters: [String: APIActionParameter]?
}

struct APIActionParameter: Codable {
    let type: String
    let placeholder: String
    let options: [String: String]?
    let order: Int?
}