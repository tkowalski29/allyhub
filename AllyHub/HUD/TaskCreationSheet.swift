import SwiftUI


struct TaskCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onTaskCreated: (TaskCreationType) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Create New Task")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 20)
            
            Text("Choose how you want to create your task")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Options
            VStack(spacing: 16) {
                // Manual Form
                TaskCreationOptionButton(
                    title: "Fill Form",
                    subtitle: "Create task manually",
                    iconName: TaskCreationType.form.iconName,
                    color: TaskCreationType.form.color
                ) {
                    onTaskCreated(.form)
                    dismiss()
                }
                
                // Audio Recording
                TaskCreationOptionButton(
                    title: "Record Audio",
                    subtitle: "Speak your task description",
                    iconName: "mic.fill", // Using mic.fill instead of mic
                    color: TaskCreationType.microphone.color
                ) {
                    onTaskCreated(.microphone)
                    dismiss()
                }
                
                // Screen Recording
                TaskCreationOptionButton(
                    title: "Record Screen",
                    subtitle: "Capture screen activity with audio",
                    iconName: TaskCreationType.screen.iconName,
                    color: TaskCreationType.screen.color
                ) {
                    onTaskCreated(.screen)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Cancel button
            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.bottom, 20)
        }
        .frame(width: 320, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct TaskCreationOptionButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}