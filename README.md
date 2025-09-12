# AllyHub - Native macOS Menu Bar Timer

A native macOS menu bar timer app built with SwiftUI + AppKit hybrid architecture. AllyHub provides a 60-minute floating timer with task management in a sleek, draggable HUD interface.

## Features

- **Menu Bar Integration**: Lives in the macOS menu bar with contextual menu controls
- **Floating HUD Timer**: Draggable, translucent floating panel with 60-minute countdown
- **Task Switching**: Built-in task management with 4 mock tasks (Email triage, Spec doc review, Prototype create, Break)
- **Hover Controls**: Intuitive controls that appear on hover (Expand, Next Task, Play/Pause, Stop/Reset)
- **Expandable Interface**: Click to expand for additional progress tracking and controls
- **Position Persistence**: Remembers window position across app restarts
- **Agent App**: No dock icon (LSUIElement = YES) - purely menu bar focused

## Technical Architecture

### Core Components

- **AppDelegate**: Main coordinator managing app lifecycle and component orchestration
- **StatusBarController**: NSStatusBar management with menu and status updates
- **FloatingPanel**: Custom NSPanel with floating behavior, dragging, and animations
- **HUDView**: SwiftUI main interface with hover controls and smooth animations
- **HUDExpandedView**: Additional panel content with progress tracking and controls
- **TimerModel**: ObservableObject for timer logic with UserDefaults persistence
- **TasksModel**: Task list management with completion tracking

### Technology Stack

- **Swift 5.9+**: Modern Swift language features
- **SwiftUI + AppKit**: Hybrid architecture for native macOS integration
- **macOS 13.0+**: Deployment target with modern macOS APIs
- **UserDefaults**: State persistence across app launches
- **Combine**: Reactive data binding and state management

## Project Structure

```
AllyHub.xcodeproj
AllyHub/
├── App/
│   ├── AllyHubApp.swift          # Main app entry point
│   └── AppDelegate.swift          # App lifecycle coordinator
├── StatusBar/
│   └── StatusBarController.swift  # Menu bar management
├── HUD/
│   ├── FloatingPanel.swift        # Custom NSPanel
│   ├── HUDView.swift             # Main SwiftUI interface
│   └── HUDExpandedView.swift     # Expanded content
├── Model/
│   ├── TimerModel.swift          # Timer logic & persistence
│   └── TasksModel.swift          # Task management
└── Resources/
    └── Info.plist                # App configuration (LSUIElement)
AllyHubTests/
├── TimerModelTests.swift         # Timer model unit tests
├── TasksModelTests.swift         # Tasks model unit tests
└── AppDelegateTests.swift        # App delegate integration tests
```

## Key Features Implementation

### Timer System
- 60-minute countdown timer with HH:MM:SS display
- Start, pause, stop, and reset functionality
- Automatic completion detection and notifications
- Background time tracking when app is closed
- UserDefaults persistence for timer state

### Floating Panel
- Custom NSPanel with `.floating` level
- Translucent background with shadow effects
- Draggable via `isMovableByWindowBackground`
- Position autosave with `setFrameAutosaveName`
- Smooth resize animations (0.25s, easeInEaseOut)
- Hover-triggered control visibility

### SwiftUI + AppKit Integration
- NSHostingView for SwiftUI content in NSPanel
- Proper lifecycle management and memory cleanup
- Combine publishers for reactive state updates
- Animation coordination between SwiftUI and AppKit

### Status Bar Integration
- NSStatusItem with dynamic icon based on timer state
- Contextual menu with timer and HUD controls
- Real-time status updates and tooltips
- Left-click to toggle HUD, right-click for menu

## Building and Running

### Requirements
- Xcode 15.0+
- macOS 13.0+ for deployment
- Swift 5.9+

### Build Instructions
1. Open `AllyHub.xcodeproj` in Xcode
2. Select the "AllyHub" scheme
3. Build and run (⌘R)

The app will appear in the menu bar with a timer icon. Left-click to show/hide the floating HUD, right-click for the contextual menu.

### Testing
Run the unit test suite with ⌘U or via the Test navigator. The test suite covers:
- Timer model functionality and edge cases
- Task management and navigation
- App delegate integration and lifecycle

## Usage

### Timer Controls
- **Start/Pause**: Click play/pause button or use menu bar controls
- **Stop**: Stop button appears when timer is running
- **Reset**: Reset button appears when timer has been used

### Task Management
- **Next Task**: Arrow right button or menu bar "Next Task"
- **Task Progress**: View in expanded mode's Progress tab
- **Complete Tasks**: Mark tasks complete in expanded Controls tab

### Interface
- **Drag**: Click and drag anywhere on the HUD to move it
- **Expand**: Click chevron up/down to expand/collapse
- **Hover**: Hover over HUD to reveal control buttons
- **Keyboard**: Supports keyboard shortcuts (⌘W to close, ⌘Space to toggle timer)

## Configuration

The app is configured as an agent application (no dock icon) via:
```xml
<key>LSUIElement</key>
<true/>
```

Position and timer state are automatically persisted across app launches using UserDefaults.

## Architecture Benefits

- **Separation of Concerns**: Clear separation between UI, business logic, and system integration
- **Testable**: Comprehensive unit test coverage for core functionality  
- **Maintainable**: Well-organized code structure with clear responsibilities
- **Native**: Leverages native macOS APIs for optimal performance and integration
- **Modern**: Uses latest Swift and SwiftUI patterns for robust, future-proof code

## Future Enhancements

- Custom timer durations
- Sound notifications
- Task import/export
- Keyboard shortcuts customization
- Multiple timer sessions
- Activity tracking and analytics