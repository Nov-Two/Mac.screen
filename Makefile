APP_NAME := MacScreen
BUILD_DIR := .build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
DIST_DIR := dist
DMG_ROOT := $(DIST_DIR)/dmg-root
DMG_PATH := $(DIST_DIR)/$(APP_NAME).dmg
SWIFT_SOURCES := $(shell find Sources/MacScreen -name '*.swift' | sort)
SIGN_IDENTITY ?= -
CODESIGN_FLAGS ?= --timestamp=none

.PHONY: build run package clean

build:
	@Scripts/generate-assets.sh
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	@cp App/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@printf 'APPL????' > $(APP_BUNDLE)/Contents/PkgInfo
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
	@codesign --force --deep --sign "$(SIGN_IDENTITY)" $(CODESIGN_FLAGS) $(APP_BUNDLE)

run: build
	open $(APP_BUNDLE)

package: build
	@rm -rf $(DMG_ROOT) $(DMG_PATH)
	@mkdir -p $(DMG_ROOT)
	@ditto $(APP_BUNDLE) $(DMG_ROOT)/$(APP_NAME).app
	@ln -s /Applications $(DMG_ROOT)/Applications
	@hdiutil create \
		-volname "$(APP_NAME)" \
		-srcfolder $(DMG_ROOT) \
		-ov \
		-format UDZO \
		$(DMG_PATH)
	@rm -rf $(DMG_ROOT)
	@echo "Created $(DMG_PATH)"

clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
