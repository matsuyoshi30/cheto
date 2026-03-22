.PHONY: build run clean

APP_NAME = cheto
APP_BUNDLE = $(APP_NAME).app
BUILD_DIR = .build/debug

build:
	swift build --disable-sandbox

# Create .app bundle and run
run: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp cheto/Info.plist $(APP_BUNDLE)/Contents/
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@# Copy Swift runtime resources if they exist
	@if [ -d "$(BUILD_DIR)/cheto_cheto.bundle" ]; then \
		mkdir -p $(APP_BUNDLE)/Contents/Resources; \
		cp -R $(BUILD_DIR)/cheto_cheto.bundle $(APP_BUNDLE)/Contents/Resources/; \
	fi
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
