import Foundation
import SwiftUI

// MARK: - Rich Message Models

struct RichMessage: Codable, Identifiable {
    let id = UUID()
    let type: String = "rich_message"
    let timestamp: Date
    let content: MessageContent

    private enum CodingKeys: String, CodingKey {
        case type, timestamp, content
    }
}

struct MessageContent: Codable {
    let blocks: [ContentBlock]
}

// MARK: - Content Block Types

enum ContentBlock: Codable, Identifiable {
    case text(TextBlock)
    case quote(QuoteBlock)
    case actions(ActionsBlock)
    case link(LinkBlock)
    case image(ImageBlock)
    case file(FileBlock)
    case video(VideoBlock)
    case code(CodeBlock)
    case list(ListBlock)
    case table(TableBlock)
    case progress(ProgressBlock)
    case alert(AlertBlock)
    case form(FormBlock)
    case card(CardBlock)
    case divider(DividerBlock)

    var id: String {
        switch self {
        case .text(let block): return "text_\(block.content.hashValue)"
        case .quote(let block): return "quote_\(block.content.hashValue)"
        case .actions(let block): return "actions_\(block.buttons.count)"
        case .link(let block): return "link_\(block.url.hashValue)"
        case .image(let block): return "image_\(block.url.hashValue)"
        case .file(let block): return "file_\(block.filename.hashValue)"
        case .video(let block): return "video_\(block.url.hashValue)"
        case .code(let block): return "code_\(block.content.hashValue)"
        case .list(let block): return "list_\(block.items.count)"
        case .table(let block): return "table_\(block.headers.count)"
        case .progress(let block): return "progress_\(block.title.hashValue)"
        case .alert(let block): return "alert_\(block.title.hashValue)"
        case .form(let block): return "form_\(block.title.hashValue)"
        case .card(let block): return "card_\(block.title.hashValue)"
        case .divider(let block): return "divider_\(block.label?.hashValue ?? 0)"
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            self = .text(try TextBlock(from: decoder))
        case "quote":
            self = .quote(try QuoteBlock(from: decoder))
        case "actions":
            self = .actions(try ActionsBlock(from: decoder))
        case "link":
            self = .link(try LinkBlock(from: decoder))
        case "image":
            self = .image(try ImageBlock(from: decoder))
        case "file":
            self = .file(try FileBlock(from: decoder))
        case "video":
            self = .video(try VideoBlock(from: decoder))
        case "code":
            self = .code(try CodeBlock(from: decoder))
        case "list":
            self = .list(try ListBlock(from: decoder))
        case "table":
            self = .table(try TableBlock(from: decoder))
        case "progress":
            self = .progress(try ProgressBlock(from: decoder))
        case "alert":
            self = .alert(try AlertBlock(from: decoder))
        case "form":
            self = .form(try FormBlock(from: decoder))
        case "card":
            self = .card(try CardBlock(from: decoder))
        case "divider":
            self = .divider(try DividerBlock(from: decoder))
        default:
            // Fallback to text block for unknown types
            self = .text(TextBlock(content: "Unsupported message type: \(type)", style: nil))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let block):
            try block.encode(to: encoder)
        case .quote(let block):
            try block.encode(to: encoder)
        case .actions(let block):
            try block.encode(to: encoder)
        case .link(let block):
            try block.encode(to: encoder)
        case .image(let block):
            try block.encode(to: encoder)
        case .file(let block):
            try block.encode(to: encoder)
        case .video(let block):
            try block.encode(to: encoder)
        case .code(let block):
            try block.encode(to: encoder)
        case .list(let block):
            try block.encode(to: encoder)
        case .table(let block):
            try block.encode(to: encoder)
        case .progress(let block):
            try block.encode(to: encoder)
        case .alert(let block):
            try block.encode(to: encoder)
        case .form(let block):
            try block.encode(to: encoder)
        case .card(let block):
            try block.encode(to: encoder)
        case .divider(let block):
            try block.encode(to: encoder)
        }
    }
}

// MARK: - Block Implementations

struct TextBlock: Codable {
    let type: String = "text"
    let content: String
    let style: TextStyle?

    private enum CodingKeys: String, CodingKey {
        case type, content, style
    }
}

struct TextStyle: Codable {
    let emphasis: Emphasis?
    let size: Size?
    let color: Color?

    enum Emphasis: String, Codable {
        case normal, bold, italic
    }

    enum Size: String, Codable {
        case small, normal, large
    }

    enum Color: String, Codable {
        case `default`, primary, success, warning, error
    }
}

struct QuoteBlock: Codable {
    let type: String = "quote"
    let content: String
    let author: String?
    let source: String?

    private enum CodingKeys: String, CodingKey {
        case type, content, author, source
    }
}

struct ActionsBlock: Codable {
    let type: String = "actions"
    let layout: Layout
    let buttons: [ActionButton]

    enum Layout: String, Codable {
        case horizontal, vertical
    }

    private enum CodingKeys: String, CodingKey {
        case type, layout, buttons
    }
}

struct ActionButton: Codable, Identifiable {
    let id: String
    let title: String
    let style: ButtonStyle
    let action: ButtonAction

    enum ButtonStyle: String, Codable {
        case primary, secondary, success, warning, destructive
    }
}

struct ButtonAction: Codable {
    let type: ActionType
    let url: String?
    let payload: [String: String]?

    enum ActionType: String, Codable {
        case callback, url
    }
}

struct LinkBlock: Codable {
    let type: String = "link"
    let url: String
    let title: String
    let description: String?
    let preview: LinkPreview?

    private enum CodingKeys: String, CodingKey {
        case type, url, title, description, preview
    }
}

struct LinkPreview: Codable {
    let imageUrl: String?
    let faviconUrl: String?

    private enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case faviconUrl = "favicon_url"
    }
}

struct ImageBlock: Codable {
    let type: String = "image"
    let url: String
    let altText: String
    let caption: String?
    let dimensions: Dimensions?
    let thumbnailUrl: String?

    private enum CodingKeys: String, CodingKey {
        case type, url
        case altText = "alt_text"
        case caption, dimensions
        case thumbnailUrl = "thumbnail_url"
    }
}

struct Dimensions: Codable {
    let width: Int
    let height: Int
}

struct FileBlock: Codable {
    let type: String = "file"
    let url: String
    let filename: String
    let size: Int
    let mimeType: String
    let description: String?

    private enum CodingKeys: String, CodingKey {
        case type, url, filename, size
        case mimeType = "mime_type"
        case description
    }
}

struct VideoBlock: Codable {
    let type: String = "video"
    let url: String
    let thumbnailUrl: String?
    let title: String?
    let duration: Int?
    let dimensions: Dimensions?

    private enum CodingKeys: String, CodingKey {
        case type, url
        case thumbnailUrl = "thumbnail_url"
        case title, duration, dimensions
    }
}

struct CodeBlock: Codable {
    let type: String = "code"
    let content: String
    let language: String?
    let title: String?
    let filename: String?

    private enum CodingKeys: String, CodingKey {
        case type, content, language, title, filename
    }
}

struct ListBlock: Codable {
    let type: String = "list"
    let style: ListStyle
    let items: [ListItem]

    enum ListStyle: String, Codable {
        case bullet, numbered, checklist
    }

    private enum CodingKeys: String, CodingKey {
        case type, style, items
    }
}

struct ListItem: Codable {
    let content: String
    let checked: Bool?
}

struct TableBlock: Codable {
    let type: String = "table"
    let headers: [String]
    let rows: [[String]]
    let caption: String?

    private enum CodingKeys: String, CodingKey {
        case type, headers, rows, caption
    }
}

struct ProgressBlock: Codable {
    let type: String = "progress"
    let title: String
    let value: Int
    let max: Int
    let label: String?
    let status: ProgressStatus?

    enum ProgressStatus: String, Codable {
        case inProgress = "in_progress"
        case completed, error
    }

    private enum CodingKeys: String, CodingKey {
        case type, title, value, max, label, status
    }
}

struct AlertBlock: Codable {
    let type: String = "alert"
    let level: AlertLevel
    let title: String
    let content: String
    let dismissible: Bool?

    enum AlertLevel: String, Codable {
        case info, success, warning, error
    }

    private enum CodingKeys: String, CodingKey {
        case type, level, title, content, dismissible
    }
}

struct FormBlock: Codable {
    let type: String = "form"
    let title: String
    let fields: [FormField]
    let submitButton: ActionButton

    private enum CodingKeys: String, CodingKey {
        case type, title, fields
        case submitButton = "submit_button"
    }
}

struct FormField: Codable, Identifiable {
    let id: String
    let type: FieldType
    let label: String
    let placeholder: String?
    let required: Bool?

    enum FieldType: String, Codable {
        case text, email, password, number, textarea
    }
}

struct CardBlock: Codable {
    let type: String = "card"
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let content: String?
    let actions: [ActionButton]?

    private enum CodingKeys: String, CodingKey {
        case type, title, subtitle
        case imageUrl = "image_url"
        case content, actions
    }
}

struct DividerBlock: Codable {
    let type: String = "divider"
    let style: DividerStyle
    let label: String?

    enum DividerStyle: String, Codable {
        case line, space, decorative
    }

    private enum CodingKeys: String, CodingKey {
        case type, style, label
    }
}

// MARK: - Extended ChatMessage for Rich Content

struct EnhancedChatMessage: Identifiable, Equatable {
    let id = UUID()
    let isUser: Bool
    let timestamp = Date()
    let content: MessageContentType

    enum MessageContentType: Equatable {
        case simple(String)
        case rich(RichMessage)

        static func == (lhs: MessageContentType, rhs: MessageContentType) -> Bool {
            switch (lhs, rhs) {
            case (.simple(let left), .simple(let right)):
                return left == right
            case (.rich(let left), .rich(let right)):
                return left.id == right.id
            default:
                return false
            }
        }
    }
}