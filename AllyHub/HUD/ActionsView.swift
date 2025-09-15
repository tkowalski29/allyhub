import SwiftUI
import UniformTypeIdentifiers

struct ActionsView: View {
    @ObservedObject var actionsManager: ActionsManager
    @State private var expandedActionId: String?
    @State private var selectedActionForParameters: ActionItem?
    @State private var parameterValues: [String: ActionParameterValue] = [:]
    @State private var showingFilePicker = false
    @State private var currentFileParameterKey: String?
    @State private var showParametersForm: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if actionsManager.showResponse {
                actionResponseView
            }
            
            actionsList
            
            if showParametersForm, let action = selectedActionForParameters {
                parametersFormView(for: action)
            }
        }
        .background(filePickerView)
    }
    
    private var actionResponseView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: actionsManager.actionResponse?.success == true ? "checkmark.circle" : "xmark.circle")
                    .foregroundStyle(actionsManager.actionResponse?.success == true ? .green : .red)
                    .font(.system(size: 16))
                
                Text("Response")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: {
                    actionsManager.showResponse = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            if let response = actionsManager.actionResponse {
                Text(response.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.leading, 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.blue.opacity(0.2))
        .transition(.slide.combined(with: .opacity))
    }
    
    private var actionsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(actionsManager.actions, id: \.id) { action in
                    actionRow(action: action)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private func actionRow(action: ActionItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Title and message
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    if !action.message.isEmpty {
                        Text(action.message)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Execute button or progress indicator
                if actionsManager.executingActionId == action.id {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 20, height: 20)
                } else {
                    Button(action: {
                        handleActionTap(action)
                    }) {
                        Image(systemName: action.parameters.isEmpty ? "play.fill" : "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Expanded info section (parameters preview)
            if expandedActionId == action.id && !action.parameters.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parameters:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    ForEach(Array(action.parameters.keys.sorted(by: { key1, key2 in
                        let param1 = action.parameters[key1]!
                        let param2 = action.parameters[key2]!
                        return param1.order < param2.order
                    })), id: \.self) { key in
                        let parameter = action.parameters[key]!
                        HStack {
                            Text(key)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text(parameter.type == "select" ? "Select" : (parameter.type == "file" ? "File" : "Text"))
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 0) // No icon, align with title
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                if isHovering && !action.parameters.isEmpty {
                    expandedActionId = action.id
                } else {
                    expandedActionId = nil
                }
            }
        }
    }
    
    private func parametersFormView(for action: ActionItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Configure \(action.title)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: {
                    closeParametersForm()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            // Parameters
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(action.parameters.keys.sorted(by: { key1, key2 in
                    let param1 = action.parameters[key1]!
                    let param2 = action.parameters[key2]!
                    return param1.order < param2.order
                })), id: \.self) { key in
                    let parameter = action.parameters[key]!
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(key.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                        
                        if parameter.type == "select", let options = parameter.options {
                            Menu {
                                ForEach(Array(options.keys.sorted()), id: \.self) { optionKey in
                                    Button(action: {
                                        parameterValues[key] = .string(optionKey)
                                    }) {
                                        Text(options[optionKey] ?? optionKey)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(getSelectDisplayValue(for: key, options: options, placeholder: parameter.placeholder))
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        } else if parameter.type == "file" {
                            Button(action: {
                                currentFileParameterKey = key
                                showingFilePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.8))
                                    
                                    Text(getFileDisplayName(for: key))
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    if case .file = parameterValues[key] {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.green)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        } else {
                            TextField(parameter.placeholder, text: Binding(
                                get: { 
                                    if case .string(let value) = parameterValues[key] {
                                        return value
                                    }
                                    return ""
                                },
                                set: { parameterValues[key] = .string($0) }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Execute button
            Button(action: {
                executeActionWithParameters(action)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Execute")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(actionsManager.executingActionId != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.4))
        .transition(.slide.combined(with: .opacity))
    }
    
    private func handleActionTap(_ action: ActionItem) {
        if action.parameters.isEmpty {
            // Execute immediately
            actionsManager.executeAction(action, parameters: [:])
        } else {
            // Show parameters form
            selectedActionForParameters = action
            parameterValues = [:]
            // Initialize with empty values for all parameters
            for (key, parameter) in action.parameters {
                if parameter.type == "file" {
                    // Don't initialize file parameters
                    continue
                } else {
                    parameterValues[key] = .string("")
                }
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                showParametersForm = true
            }
        }
    }
    
    private func executeActionWithParameters(_ action: ActionItem) {
        actionsManager.executeAction(action, parameters: parameterValues)
        closeParametersForm()
    }
    
    private func closeParametersForm() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showParametersForm = false
        }
        selectedActionForParameters = nil
        parameterValues = [:]
    }
    
    private func getFileDisplayName(for key: String) -> String {
        if case .file(let url) = parameterValues[key] {
            return url.lastPathComponent
        } else {
            return "Choose file..."
        }
    }
    
    private func getSelectDisplayValue(for key: String, options: [String: String], placeholder: String) -> String {
        if case .string(let value) = parameterValues[key], !value.isEmpty {
            return options[value] ?? value
        } else {
            return placeholder
        }
    }
}

// MARK: - File Picker Extension
extension ActionsView {
    var filePickerView: some View {
        Button("Select File") {
            showingFilePicker = true
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data, .image, .text, .pdf, .audio, .video],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let fileURL = files.first, let key = currentFileParameterKey {
                    // Start accessing security-scoped resource
                    if fileURL.startAccessingSecurityScopedResource() {
                        parameterValues[key] = .file(fileURL)
                        // Note: In a real app, you might want to copy the file to a temporary location
                        // and call stopAccessingSecurityScopedResource() after use
                    }
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
            currentFileParameterKey = nil
        }
    }
}