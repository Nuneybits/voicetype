.PHONY: build test clean release icon bundle dmg run

APP_NAME := VoiceType
APP_BUNDLE := dist/$(APP_NAME).app
APP_CONTENTS := $(APP_BUNDLE)/Contents
APP_BINARY := $(APP_CONTENTS)/MacOS/$(APP_NAME)
APP_RESOURCES := $(APP_CONTENTS)/Resources
ICON_SOURCE := VoiceType/Assets/AppIcon-1024.png
ICON_FILE := VoiceType/Assets/AppIcon.icns
SIGN_IDENTITY ?= -

build:
	cd VoiceType && swift build

clean:
	cd VoiceType && swift package clean
	rm -rf dist

release:
	cd VoiceType && swift build -c release

icon: $(ICON_FILE)

$(ICON_FILE): $(ICON_SOURCE) scripts/build_icns.py
	@echo "Generating app icon..."
	@mkdir -p VoiceType/Assets
	@python3 scripts/build_icns.py $(ICON_SOURCE) $(ICON_FILE)

# Create a macOS .app bundle from the release binary
bundle: release icon
	@echo "Creating $(APP_NAME).app bundle..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_CONTENTS)/MacOS
	@mkdir -p $(APP_RESOURCES)
	@cp VoiceType/.build/release/$(APP_NAME) $(APP_BINARY)
	@cp VoiceType/Info.plist $(APP_CONTENTS)/Info.plist
	@cp $(ICON_FILE) $(APP_RESOURCES)/AppIcon.icns
	@echo "APPL????" > $(APP_CONTENTS)/PkgInfo
	@codesign --force --sign "$(SIGN_IDENTITY)" $(APP_BUNDLE)
	@echo "$(APP_NAME).app created at $(APP_BUNDLE)"

# Create a DMG for distribution
dmg: bundle
	@echo "Creating DMG..."
	@rm -rf dist/dmg
	@mkdir -p dist/dmg
	@cp -R $(APP_BUNDLE) dist/dmg/$(APP_NAME).app
	@ln -sfn /Applications dist/dmg/Applications
	@rm -f dist/$(APP_NAME).dmg
	@hdiutil create -volname "$(APP_NAME)" -srcfolder dist/dmg -ov -format UDZO dist/$(APP_NAME).dmg
	@echo "DMG created at dist/$(APP_NAME).dmg"

# Run the app locally
run: build
	cd VoiceType && .build/debug/$(APP_NAME)
