APP_NAME := MacScreen
BUILD_DIR := .build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
SWIFT_SOURCES := $(shell find Sources/MacScreen -name '*.swift' | sort)

.PHONY: build run clean

build:
	@Scripts/generate-assets.sh
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	@cp App/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@rm -rf $(APP_BUNDLE)/Contents/Resources/Videos
	@ditto Videos $(APP_BUNDLE)/Contents/Resources/Videos
	@ditto Assets/Thumbnails $(APP_BUNDLE)/Contents/Resources/Thumbnails
	@cp Assets/AppIcon/MacScreenIcon.icns $(APP_BUNDLE)/Contents/Resources/MacScreenIcon.icns
	@DEVELOPER_DIR_CANDIDATE="$$(find "$(HOME)/Applications" /Applications -maxdepth 3 -path '*/Xcode*.app/Contents/Developer' -print -quit 2>/dev/null)"; \
	if [ -n "$$DEVELOPER_DIR_CANDIDATE" ]; then \
		echo "Using Xcode: $$DEVELOPER_DIR_CANDIDATE"; \
		DEVELOPER_DIR="$$DEVELOPER_DIR_CANDIDATE" xcrun swiftc \
			-target arm64-apple-macosx14.0 \
			-parse-as-library \
			$(SWIFT_SOURCES) \
			-o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME); \
	else \
		echo "Xcode not found. Install Xcode 16.4 to build the Swift app."; \
		xcrun swiftc \
			-target arm64-apple-macosx14.0 \
			-parse-as-library \
			$(SWIFT_SOURCES) \
			-o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME); \
	fi

run: build
	open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)
