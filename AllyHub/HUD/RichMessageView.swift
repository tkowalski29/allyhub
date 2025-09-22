import SwiftUI
import Foundation

// MARK: - Rich Message View

struct RichMessageView: View {
    let richMessage: RichMessage
    let isCompact: Bool
    let onButtonAction: (String, [String: String]?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
            ForEach(richMessage.content.blocks.prefix(isCompact ? 3 : richMessage.content.blocks.count), id: \.id) { block in
                ContentBlockView(
                    block: block,
                    isCompact: isCompact,
                    onButtonAction: onButtonAction
                )
            }

            if isCompact && richMessage.content.blocks.count > 3 {
                Text("...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Content Block View

struct ContentBlockView: View {
    let block: ContentBlock
    let isCompact: Bool
    let onButtonAction: (String, [String: String]?) -> Void

    var body: some View {
        Group {
            switch block {
            case .text(let textBlock):
                TextBlockView(block: textBlock, isCompact: isCompact)
            case .quote(let quoteBlock):
                QuoteBlockView(block: quoteBlock, isCompact: isCompact)
            case .actions(let actionsBlock):
                ActionsBlockView(block: actionsBlock, isCompact: isCompact, onButtonAction: onButtonAction)
            case .link(let linkBlock):
                LinkBlockView(block: linkBlock, isCompact: isCompact)
            case .image(let imageBlock):
                ImageBlockView(block: imageBlock, isCompact: isCompact)
            case .file(let fileBlock):
                FileBlockView(block: fileBlock, isCompact: isCompact)
            case .video(let videoBlock):
                VideoBlockView(block: videoBlock, isCompact: isCompact)
            case .code(let codeBlock):
                CodeBlockView(block: codeBlock, isCompact: isCompact)
            case .list(let listBlock):
                ListBlockView(block: listBlock, isCompact: isCompact)
            case .table(let tableBlock):
                TableBlockView(block: tableBlock, isCompact: isCompact)
            case .progress(let progressBlock):
                ProgressBlockView(block: progressBlock, isCompact: isCompact)
            case .alert(let alertBlock):
                AlertBlockView(block: alertBlock, isCompact: isCompact)
            case .form(let formBlock):
                FormBlockView(block: formBlock, isCompact: isCompact, onButtonAction: onButtonAction)
            case .card(let cardBlock):
                CardBlockView(block: cardBlock, isCompact: isCompact, onButtonAction: onButtonAction)
            case .divider(let dividerBlock):
                DividerBlockView(block: dividerBlock, isCompact: isCompact)
            }
        }
    }
}

// MARK: - Text Block View

struct TextBlockView: View {
    let block: TextBlock
    let isCompact: Bool

    var body: some View {
        Text(block.content)
            .font(fontSize)
            .fontWeight(fontWeight)
            .foregroundColor(textColor)
            .lineLimit(isCompact ? 2 : nil)
    }

    private var fontSize: Font {
        let baseSize: Font = isCompact ? .caption : .body
        guard let size = block.style?.size else { return baseSize }

        switch size {
        case .small:
            return isCompact ? .caption2 : .caption
        case .normal:
            return baseSize
        case .large:
            return isCompact ? .body : .title3
        }
    }

    private var fontWeight: Font.Weight {
        guard let emphasis = block.style?.emphasis else { return .regular }

        switch emphasis {
        case .normal:
            return .regular
        case .bold:
            return .bold
        case .italic:
            return .regular // Handle with separate modifier if needed
        }
    }

    private var textColor: Color {
        guard let color = block.style?.color else { return .white }

        switch color {
        case .default:
            return .white
        case .primary:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

// MARK: - Quote Block View

struct QuoteBlockView: View {
    let block: QuoteBlock
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(block.content)
                        .font(isCompact ? .caption : .body)
                        .fontStyle(.italic)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(isCompact ? 2 : nil)

                    if !isCompact, let author = block.author {
                        Text("— \(author)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()
            }
        }
        .padding(.vertical, isCompact ? 4 : 8)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Actions Block View

struct ActionsBlockView: View {
    let block: ActionsBlock
    let isCompact: Bool
    let onButtonAction: (String, [String: String]?) -> Void

    var body: some View {
        let maxButtons = isCompact ? 2 : block.buttons.count

        if block.layout == .horizontal {
            HStack(spacing: 8) {
                ForEach(Array(block.buttons.prefix(maxButtons).enumerated()), id: \.element.id) { index, button in
                    ActionButtonView(
                        button: button,
                        isCompact: isCompact,
                        onAction: onButtonAction
                    )
                }

                if isCompact && block.buttons.count > maxButtons {
                    Text("+\(block.buttons.count - maxButtons)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        } else {
            VStack(spacing: 6) {
                ForEach(Array(block.buttons.prefix(maxButtons).enumerated()), id: \.element.id) { index, button in
                    ActionButtonView(
                        button: button,
                        isCompact: isCompact,
                        onAction: onButtonAction
                    )
                }
            }
        }
    }
}

struct ActionButtonView: View {
    let button: ActionButton
    let isCompact: Bool
    let onAction: (String, [String: String]?) -> Void

    var body: some View {
        Button(action: {
            if button.action.type == .url, let url = button.action.url {
                if let nsUrl = URL(string: url) {
                    NSWorkspace.shared.open(nsUrl)
                }
            } else {
                onAction(button.id, button.action.payload)
            }
        }) {
            Text(button.title)
                .font(isCompact ? .caption : .body)
                .fontWeight(.medium)
                .foregroundColor(buttonTextColor)
                .padding(.horizontal, isCompact ? 8 : 12)
                .padding(.vertical, isCompact ? 4 : 6)
                .background(buttonBackgroundColor)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var buttonTextColor: Color {
        switch button.style {
        case .primary:
            return .white
        case .secondary:
            return .white.opacity(0.9)
        case .success:
            return .white
        case .warning:
            return .black
        case .destructive:
            return .white
        }
    }

    private var buttonBackgroundColor: Color {
        switch button.style {
        case .primary:
            return .blue
        case .secondary:
            return .white.opacity(0.2)
        case .success:
            return .green
        case .warning:
            return .orange
        case .destructive:
            return .red
        }
    }
}

// MARK: - Link Block View

struct LinkBlockView: View {
    let block: LinkBlock
    let isCompact: Bool

    var body: some View {
        Button(action: {
            if let url = URL(string: block.url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(block.title)
                        .font(isCompact ? .caption : .body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .lineLimit(1)

                    if !isCompact, let description = block.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.7))
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Block View

struct ImageBlockView: View {
    let block: ImageBlock
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: URL(string: block.url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            .frame(maxHeight: isCompact ? 60 : 200)
            .cornerRadius(8)

            if !isCompact, let caption = block.caption {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Additional Block Views (Simplified for brevity)

struct FileBlockView: View {
    let block: FileBlock
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .foregroundColor(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(block.filename)
                    .font(isCompact ? .caption : .body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if !isCompact {
                    Text(formatFileSize(block.size))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            Button("Download") {
                if let url = URL(string: block.url) {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct VideoBlockView: View {
    let block: VideoBlock
    let isCompact: Bool

    var body: some View {
        Button(action: {
            if let url = URL(string: block.url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            ZStack {
                AsyncImage(url: URL(string: block.thumbnailUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                }
                .frame(maxHeight: isCompact ? 60 : 150)
                .cornerRadius(8)

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CodeBlockView: View {
    let block: CodeBlock
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isCompact, let title = block.title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.content)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green.opacity(0.9))
                    .padding(8)
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
            .frame(maxHeight: isCompact ? 40 : 100)
        }
    }
}

struct ListBlockView: View {
    let block: ListBlock
    let isCompact: Bool

    var body: some View {
        let itemsToShow = isCompact ? Array(block.items.prefix(3)) : block.items

        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(itemsToShow.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 6) {
                    Text(listPrefix(for: index, style: block.style))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 20, alignment: .leading)

                    Text(item.content)
                        .font(isCompact ? .caption : .body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(isCompact ? 1 : nil)

                    Spacer()
                }
            }

            if isCompact && block.items.count > 3 {
                Text("...and \(block.items.count - 3) more")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    private func listPrefix(for index: Int, style: ListBlock.ListStyle) -> String {
        switch style {
        case .bullet:
            return "•"
        case .numbered:
            return "\(index + 1)."
        case .checklist:
            return block.items[index].checked == true ? "☑" : "☐"
        }
    }
}

struct TableBlockView: View {
    let block: TableBlock
    let isCompact: Bool

    var body: some View {
        if isCompact {
            // Simplified table view for compact mode
            VStack(alignment: .leading, spacing: 2) {
                Text("Table: \(block.headers.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)

                Text("\(block.rows.count) rows")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Headers
                    HStack(spacing: 0) {
                        ForEach(block.headers, id: \.self) { header in
                            Text(header)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(minWidth: 80, alignment: .leading)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                        }
                    }

                    // Rows
                    ForEach(Array(block.rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(minWidth: 80, alignment: .leading)
                                    .padding(4)
                            }
                        }
                        .background(Color.white.opacity(0.02))
                    }
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)
        }
    }
}

struct ProgressBlockView: View {
    let block: ProgressBlock
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(block.title)
                    .font(isCompact ? .caption : .body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                if let label = block.label {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            ProgressView(value: Double(block.value), total: Double(block.max))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .frame(height: isCompact ? 4 : 6)
        }
    }

    private var progressColor: Color {
        switch block.status {
        case .completed:
            return .green
        case .error:
            return .red
        case .inProgress, .none:
            return .blue
        }
    }
}

struct AlertBlockView: View {
    let block: AlertBlock
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: alertIcon)
                .foregroundColor(alertColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(isCompact ? .caption : .body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if !isCompact {
                    Text(block.content)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                }
            }

            Spacer()
        }
        .padding(8)
        .background(alertColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(alertColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var alertIcon: String {
        switch block.level {
        case .info:
            return "info.circle"
        case .success:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }

    private var alertColor: Color {
        switch block.level {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

struct FormBlockView: View {
    let block: FormBlock
    let isCompact: Bool
    let onButtonAction: (String, [String: String]?) -> Void

    @State private var formData: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(block.title)
                .font(isCompact ? .caption : .body)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if !isCompact {
                VStack(spacing: 6) {
                    ForEach(block.fields) { field in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(field.label)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            TextField(field.placeholder ?? "", text: Binding(
                                get: { formData[field.id, default: ""] },
                                set: { formData[field.id] = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }

                    ActionButtonView(
                        button: block.submitButton,
                        isCompact: false,
                        onAction: { id, _ in
                            onButtonAction(id, formData)
                        }
                    )
                }
            } else {
                Text("Form: \(block.fields.count) fields")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CardBlockView: View {
    let block: CardBlock
    let isCompact: Bool
    let onButtonAction: (String, [String: String]?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = block.imageUrl, !isCompact {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                }
                .frame(height: 100)
                .clipped()
                .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(isCompact ? .caption : .body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if let subtitle = block.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                if !isCompact, let content = block.content {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                }
            }

            if let actions = block.actions, !actions.isEmpty && !isCompact {
                HStack(spacing: 6) {
                    ForEach(actions.prefix(2)) { action in
                        ActionButtonView(
                            button: action,
                            isCompact: false,
                            onAction: onButtonAction
                        )
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct DividerBlockView: View {
    let block: DividerBlock
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 4) {
            if let label = block.label, !isCompact {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            switch block.style {
            case .line:
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
            case .space:
                Spacer()
                    .frame(height: isCompact ? 8 : 16)
            case .decorative:
                Text("• • •")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}