# AllyHub Makefile
# Simple makefile to open the Xcode project

.PHONY: run

run:
	@echo "🚀 Opening AllyHub project in Xcode..."
	@open AllyHub.xcodeproj
	@echo ""
	@echo "📋 Next steps:"
	@echo "  • Select the AllyHub scheme in Xcode"
	@echo "  • Press Cmd+R to build and run the project"
	@echo "  • Or use the Run button in Xcode toolbar"
	@echo ""
	@echo "✨ The app will appear in your menu bar when running!"