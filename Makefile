APP_NAME := MacScreen
BUILD_DIR := .build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
DIST_DIR := dist
DMG_ROOT := $(DIST_DIR)/dmg-root
DMG_PATH := $(DIST_DIR)/$(APP_NAME).dmg
SIGN_IDENTITY ?= -
CODESIGN_FLAGS ?= --timestamp=none

.PHONY: build run package clean

build:
	@Scripts/generate-assets.sh
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources $(APP_BUNDLE)/Contents/Frameworks
	@SPARKLE_PUBLIC_ED_KEY_VALUE="$${SPARKLE_PUBLIC_ED_KEY:-$$(cat .sparkle-public-ed-key 2>/dev/null || true)}"; \
	if [ -z "$$SPARKLE_PUBLIC_ED_KEY_VALUE" ]; then \
		SPARKLE_PUBLIC_ED_KEY_VALUE='$$(SPARKLE_PUBLIC_ED_KEY)'; \
	fi; \
	sed "s|\$$(SPARKLE_PUBLIC_ED_KEY)|$$SPARKLE_PUBLIC_ED_KEY_VALUE|g" App/Info.plist > $(APP_BUNDLE)/Contents/Info.plist
	@printf 'APPL????' > $(APP_BUNDLE)/Contents/PkgInfo
	@rm -rf $(APP_BUNDLE)/Contents/Resources/Videos
	@ditto Videos $(APP_BUNDLE)/Contents/Resources/Videos
	@ditto Assets/Thumbnails $(APP_BUNDLE)/Contents/Resources/Thumbnails
	@ditto Assets/Links $(APP_BUNDLE)/Contents/Resources/Links
	@cp Assets/AppIcon/MacScreenIcon.icns $(APP_BUNDLE)/Contents/Resources/MacScreenIcon.icns
	@DEVELOPER_DIR_CANDIDATE="$$(find "$(HOME)/Applications" /Applications -maxdepth 3 -path '*/Xcode*.app/Contents/Developer' -print -quit 2>/dev/null)"; \
	if [ -n "$$DEVELOPER_DIR_CANDIDATE" ]; then \
		echo "Using Xcode: $$DEVELOPER_DIR_CANDIDATE"; \
		DEVELOPER_DIR="$$DEVELOPER_DIR_CANDIDATE" swift build -c release --arch arm64; \
	else \
		echo "Xcode not found. Install Xcode 16.4 to build the Swift app."; \
		swift build -c release --arch arm64; \
	fi
	@EXECUTABLE_PATH="$$(find $(BUILD_DIR) -path '*/release/$(APP_NAME)' -type f -perm +111 -print -quit 2>/dev/null)"; \
	if [ -z "$$EXECUTABLE_PATH" ]; then \
		echo "Built executable not found."; \
		exit 1; \
	fi; \
	cp "$$EXECUTABLE_PATH" $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME); \
	install_name_tool -add_rpath @loader_path/../Frameworks $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) 2>/dev/null || true
	@SPARKLE_FRAMEWORK_PATH="$$(find $(BUILD_DIR)/artifacts -path '*/Sparkle.framework' -type d -print -quit 2>/dev/null)"; \
	if [ -z "$$SPARKLE_FRAMEWORK_PATH" ]; then \
		echo "Sparkle.framework not found. Run swift package resolve and build again."; \
		exit 1; \
	fi; \
	rm -rf $(APP_BUNDLE)/Contents/Frameworks/Sparkle.framework; \
	ditto "$$SPARKLE_FRAMEWORK_PATH" $(APP_BUNDLE)/Contents/Frameworks/Sparkle.framework
	@codesign --force --deep --sign "$(SIGN_IDENTITY)" $(CODESIGN_FLAGS) $(APP_BUNDLE)

run: build
	open $(APP_BUNDLE)

package: build
	@rm -rf $(DMG_ROOT) $(DMG_PATH)
	@mkdir -p $(DMG_ROOT)
	@ditto $(APP_BUNDLE) $(DMG_ROOT)/$(APP_NAME).app
	@cp Distribution/安装说明.txt $(DMG_ROOT)/安装说明.txt
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
