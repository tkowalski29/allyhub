# AllyHub Makefile
# Build and install commands for AllyHub macOS app

# Variables
APP_NAME = AllyHub
PROJECT_FILE = AllyHub.xcodeproj
SCHEME = AllyHub
CONFIGURATION = Release
BUILD_DIR = build
APP_PATH = $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app
INSTALL_PATH = /Applications
TIMEOUT = 300

.PHONY: run build clean install uninstall archive help quick-install

cc:
	ccusage blocks --live

# Default target
help:
	@echo "🏗️  AllyHub Build System"
	@echo ""
	@echo "Available commands:"
	@echo "  make run        - Open project in Xcode"
	@echo "  make build      - Build release version"
	@echo "  make install    - Build and install to /Applications"
	@echo "  make uninstall  - Remove from /Applications"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make archive       - Create distributable .app bundle"
	@echo "  make quick-install - Quick build and install (recommended)"
	@echo ""

run:
	@echo "🚀 Opening AllyHub project in Xcode..."
	@open $(PROJECT_FILE)
	@echo ""
	@echo "📋 Next steps:"
	@echo "  • Select the AllyHub scheme in Xcode"
	@echo "  • Press Cmd+R to build and run the project"
	@echo "  • Or use the Run button in Xcode toolbar"
	@echo ""
	@echo "✨ The app will appear in your menu bar when running!"

build:
	@echo "🔨 Building $(APP_NAME) ($(CONFIGURATION))..."
	@timeout $(TIMEOUT) xcodebuild -project $(PROJECT_FILE) \
				-scheme $(SCHEME) \
				-configuration $(CONFIGURATION) \
				-derivedDataPath $(BUILD_DIR) \
				build || echo "⚠️  Build timeout or failed, checking results..."
	@if [ -d "$(APP_PATH)" ] && [ -x "$(APP_PATH)/Contents/MacOS/$(APP_NAME)" ]; then \
		echo "✅ Build completed: $(APP_PATH)"; \
	else \
		echo "❌ Build failed - executable not found"; \
		exit 1; \
	fi

install: build
	@echo "📦 Installing $(APP_NAME) to $(INSTALL_PATH)..."
	@if [ -d "$(INSTALL_PATH)/$(APP_NAME).app" ]; then \
		echo "⚠️  Removing existing installation..."; \
		rm -rf "$(INSTALL_PATH)/$(APP_NAME).app"; \
	fi
	@cp -R "$(APP_PATH)" "$(INSTALL_PATH)/"
	@echo "✅ $(APP_NAME) installed successfully!"
	@echo "🚀 You can now run $(APP_NAME) from Applications or Spotlight"

uninstall:
	@echo "🗑️  Uninstalling $(APP_NAME)..."
	@if [ -d "$(INSTALL_PATH)/$(APP_NAME).app" ]; then \
		rm -rf "$(INSTALL_PATH)/$(APP_NAME).app"; \
		echo "✅ $(APP_NAME) uninstalled successfully!"; \
	else \
		echo "ℹ️  $(APP_NAME) is not installed in $(INSTALL_PATH)"; \
	fi

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@xcodebuild -project $(PROJECT_FILE) clean
	@echo "✅ Clean completed"

quick-install:
	@echo "⚡ Quick build and install (Debug configuration)..."
	@xcodebuild -project $(PROJECT_FILE) \
				-scheme $(SCHEME) \
				-configuration Debug \
				build CONFIGURATION_BUILD_DIR=build/Debug
	@if [ -d "build/Debug/$(APP_NAME).app" ]; then \
		echo "📦 Installing to /Applications..."; \
		if [ -d "$(INSTALL_PATH)/$(APP_NAME).app" ]; then \
			rm -rf "$(INSTALL_PATH)/$(APP_NAME).app"; \
		fi; \
		cp -R "build/Debug/$(APP_NAME).app" "$(INSTALL_PATH)/"; \
		echo "✅ $(APP_NAME) installed! Launch from Applications or Spotlight"; \
		echo "🚀 Tip: Press Control+Shift+A to toggle the panel"; \
	else \
		echo "❌ Build failed"; \
		exit 1; \
	fi

archive:
	@echo "📦 Creating archive for distribution..."
	@xcodebuild -project $(PROJECT_FILE) \
				-scheme $(SCHEME) \
				-configuration $(CONFIGURATION) \
				-derivedDataPath $(BUILD_DIR) \
				archive -archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive
	@echo "✅ Archive created: $(BUILD_DIR)/$(APP_NAME).xcarchive"
	@echo "💡 Use Xcode Organizer to export for distribution"