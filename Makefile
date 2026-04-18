.PHONY: build test clean release bundle dmg run

APP_NAME := VoiceType
APP_BUNDLE := dist/$(APP_NAME).app
APP_CONTENTS := $(APP_BUNDLE)/Contents
APP_BINARY := $(APP_CONTENTS)/MacOS/$(APP_NAME)
APP_RESOURCES := $(APP_CONTENTS)/Resources
ICON_FILE := VoiceType/Assets/AppIcon.icns
DMG_INSTALL_NOTE := docs/INSTALL FIRST.txt
SIGN_IDENTITY ?= -

build:
	cd VoiceType && swift build

clean:
	cd VoiceType && swift package clean
	rm -rf dist

release:
	cd VoiceType && swift build -c release

# Create a macOS .app bundle from the release binary
bundle: release
	@echo "Creating $(APP_NAME).app bundle..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_CONTENTS)/MacOS
	@mkdir -p $(APP_RESOURCES)
	@cp VoiceType/.build/release/$(APP_NAME) $(APP_BINARY)
	@cp VoiceType/Info.plist $(APP_CONTENTS)/Info.plist
	@cp $(ICON_FILE) $(APP_RESOURCES)/AppIcon.icns
	@xattr -cr $(APP_BUNDLE)
	@echo "APPL????" > $(APP_CONTENTS)/PkgInfo
	@codesign --force --sign "$(SIGN_IDENTITY)" $(APP_BUNDLE)
	@echo "$(APP_NAME).app created at $(APP_BUNDLE)"

# Create a DMG for distribution
dmg: bundle
	@echo "Creating DMG..."
	@rm -rf dist/dmg
	@mkdir -p dist/dmg
	@cp -R $(APP_BUNDLE) dist/dmg/$(APP_NAME).app
	@cp "$(DMG_INSTALL_NOTE)" "dist/dmg/INSTALL FIRST.txt"
	@sh scripts/create_applications_alias.sh "$(PWD)/dist/dmg"
	@rm -f dist/$(APP_NAME).dmg
	@hdiutil create -volname "$(APP_NAME)" -srcfolder dist/dmg -ov -format UDZO dist/$(APP_NAME).dmg
	@echo "DMG created at dist/$(APP_NAME).dmg"

# Run the app locally
run: build
	cd VoiceType && .build/debug/$(APP_NAME)
