import Foundation
import SwiftUI

// MARK: - File Upload Service
// Service for uploading audio and video recordings to the server

@MainActor
final class FileUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private var uploadTask: URLSessionUploadTask?
    
    // MARK: - Public Methods
    
    /// Upload audio recording to server
    func uploadAudioRecording(
        from fileURL: URL,
        to endpoint: String,
        withMetadata metadata: AudioUploadMetadata
    ) async -> UploadResult {
        return await uploadFile(
            from: fileURL,
            to: endpoint,
            metadata: metadata,
            fieldName: "recording_file",
            contentType: "audio/mp4"
        )
    }
    
    /// Upload screen recording to server
    func uploadScreenRecording(
        from fileURL: URL,
        to endpoint: String,
        withMetadata metadata: ScreenUploadMetadata
    ) async -> UploadResult {
        return await uploadFile(
            from: fileURL,
            to: endpoint,
            metadata: metadata,
            fieldName: "recording_file",
            contentType: "video/quicktime"
        )
    }
    
    /// Cancel current upload
    func cancelUpload() {
        uploadTask?.cancel()
        uploadTask = nil
        isUploading = false
        uploadProgress = 0.0
    }
    
    // MARK: - Private Methods
    
    private func uploadFile<T: UploadMetadata>(
        from fileURL: URL,
        to endpoint: String,
        metadata: T,
        fieldName: String,
        contentType: String
    ) async -> UploadResult {
        guard let url = URL(string: endpoint) else {
            return UploadResult(success: false, error: "Invalid endpoint URL")
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return UploadResult(success: false, error: "File not found at path: \(fileURL.path)")
        }
        
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let multipartData = try createMultipartData(
                fileData: fileData,
                fileName: fileURL.lastPathComponent,
                fieldName: fieldName,
                contentType: contentType,
                metadata: metadata
            )
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("\(multipartData.count)", forHTTPHeaderField: "Content-Length")
            
            let result = try await performUpload(request: request, data: multipartData)
            
            isUploading = false
            uploadProgress = 1.0
            
            return result
            
        } catch {
            isUploading = false
            errorMessage = "Upload failed: \(error.localizedDescription)"
            
            return UploadResult(success: false, error: error.localizedDescription)
        }
    }
    
    private let boundary = "AllyHub-Upload-Boundary-\(UUID().uuidString)"
    
    private func createMultipartData<T: UploadMetadata>(
        fileData: Data,
        fileName: String,
        fieldName: String,
        contentType: String,
        metadata: T
    ) throws -> Data {
        var data = Data()
        
        // Add metadata as JSON
        let metadataJSON = try JSONEncoder().encode(metadata)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"task_data\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        data.append(metadataJSON)
        data.append("\r\n".data(using: .utf8)!)
        
        // Add file data
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
    
    private func performUpload(request: URLRequest, data: Data) async throws -> UploadResult {
        return try await withCheckedThrowingContinuation { continuation in
            uploadTask = session.uploadTask(with: request, from: data) { [weak self] responseData, response, error in
                Task { @MainActor in
                    self?.uploadTask = nil
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(returning: UploadResult(success: false, error: "Invalid response"))
                        return
                    }
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        // Parse response if needed
                        var serverResponse: String?
                        if let responseData = responseData {
                            serverResponse = String(data: responseData, encoding: .utf8)
                        }
                        
                        continuation.resume(returning: UploadResult(
                            success: true,
                            serverResponse: serverResponse
                        ))
                    } else {
                        let errorMessage = "Server returned status code: \(httpResponse.statusCode)"
                        continuation.resume(returning: UploadResult(success: false, error: errorMessage))
                    }
                }
            }
            
            uploadTask?.resume()
        }
    }
}

// MARK: - Supporting Types

struct UploadResult {
    let success: Bool
    let serverResponse: String?
    let error: String?
    
    init(success: Bool, serverResponse: String? = nil, error: String? = nil) {
        self.success = success
        self.serverResponse = serverResponse
        self.error = error
    }
    
    var isSuccess: Bool { success }
}

// MARK: - Upload Metadata Protocols

protocol UploadMetadata: Codable {
    var title: String { get }
    var description: String { get }
    var priority: String { get }
    var creationType: String { get }
    var userId: String? { get }
    var tags: [String]? { get }
}

struct AudioUploadMetadata: UploadMetadata {
    let title: String
    let description: String
    let priority: String
    let creationType: String
    let transcription: String?
    let duration: TimeInterval?
    let userId: String?
    let tags: [String]?
    let dueDate: String? // ISO8601 timestamp
    
    init(
        title: String,
        description: String,
        priority: TaskPriority,
        transcription: String? = nil,
        duration: TimeInterval? = nil,
        userId: String? = nil,
        tags: [String]? = nil,
        dueDate: Date? = nil
    ) {
        self.title = title
        self.description = description
        self.priority = priority.rawValue
        self.creationType = "microphone"
        self.transcription = transcription
        self.duration = duration
        self.userId = userId
        self.tags = tags
        self.dueDate = dueDate?.ISO8601Format()
    }
}

struct ScreenUploadMetadata: UploadMetadata {
    let title: String
    let description: String
    let priority: String
    let creationType: String
    let appName: String?
    let recordingMode: String?
    let duration: TimeInterval?
    let userId: String?
    let tags: [String]?
    let dueDate: String? // ISO8601 timestamp
    
    init(
        title: String,
        description: String,
        priority: TaskPriority,
        appName: String? = nil,
        recordingMode: String? = nil,
        duration: TimeInterval? = nil,
        userId: String? = nil,
        tags: [String]? = nil,
        dueDate: Date? = nil
    ) {
        self.title = title
        self.description = description
        self.priority = priority.rawValue
        self.creationType = "screen"
        self.appName = appName
        self.recordingMode = recordingMode
        self.duration = duration
        self.userId = userId
        self.tags = tags
        self.dueDate = dueDate?.ISO8601Format()
    }
}

// MARK: - Upload Progress View

struct UploadProgressView: View {
    let uploadService: FileUploadService
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Uploading Recording")
                .font(.headline)
                .foregroundStyle(.white)
            
            VStack(spacing: 8) {
                ProgressView(value: uploadService.uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 200)
                
                Text("\(Int(uploadService.uploadProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                
                if uploadService.isUploading {
                    Text("Please wait...")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            if let error = uploadService.errorMessage {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Cancel") {
                uploadService.cancelUpload()
                onCancel()
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - File Upload Integration Guide

/*
 Integration with AudioRecorderView and ScreenRecorderView:
 
 1. Add FileUploadService to view managers:
    private let uploadService = FileUploadService()
 
 2. Add upload option to task creation:
    - Show upload progress overlay
    - Handle upload success/failure
    - Integrate with task creation after upload
 
 3. Error handling:
    - Network connectivity issues
    - File size limitations
    - Server response validation
    - Retry mechanisms
 
 4. Configuration:
    - Add upload endpoints to CommunicationSettings
    - Configure timeout and retry policies
    - Handle authentication if required
 
 5. User experience:
    - Progress indicators
    - Cancel functionality
    - Background uploads
    - Upload queue management
*/

#Preview {
    struct UploadPreview: View {
        @StateObject private var uploadService = FileUploadService()
        
        var body: some View {
            VStack(spacing: 20) {
                Text("File Upload Service Preview")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    Text("Upload Status: Ready")
                        .foregroundStyle(.green)
                    
                    Button("Mock Upload Display") {
                        print("File upload service preview")
                    }
                }
            }
            .padding()
        }
    }
    
    return UploadPreview()
        .preferredColorScheme(.dark)
}