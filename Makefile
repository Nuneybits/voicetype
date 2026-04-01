.PHONY: build test clean release bundle

build:
	cd VoiceType && swift build

clean:
	cd VoiceType && swift package clean

release:
	cd VoiceType && swift build -c release

# Create a macOS .app bundle from the release binary
bundle: release
	@echo "Creating VoiceType.app bundle..."
	@rm -rf dist/VoiceType.app
	@mkdir -p dist/VoiceType.app/Contents/MacOS
	@mkdir -p dist/VoiceType.app/Contents/Resources
	@cp VoiceType/.build/release/VoiceType dist/VoiceType.app/Contents/MacOS/VoiceType
	@cp VoiceType/Info.plist dist/VoiceType.app/Contents/Info.plist
	@echo "APPL????" > dist/VoiceType.app/Contents/PkgInfo
	@echo "VoiceType.app created at dist/VoiceType.app"

# Create a DMG for distribution
dmg: bundle
	@echo "Creating DMG..."
	@rm -f dist/VoiceType.dmg
	@hdiutil create -volname "VoiceType" -srcfolder dist/VoiceType.app -ov -format UDZO dist/VoiceType.dmg
	@echo "DMG created at dist/VoiceType.dmg"

# Run the app locally
run: build
	cd VoiceType && .build/debug/VoiceType
