.PHONY: gen build run clean build-prod bump-major bump-minor bump-patch bump-build
build-prod: gen
	@cd scripts && ./sync-version.sh
	@cd scripts && ./bump-build.sh
	xcodebuild -project SpaceCommand.xcodeproj -scheme SpaceCommand -configuration Release \
		CONFIGURATION_BUILD_DIR=$(BUILD_DIR)/Release \
		build
	chmod +x $(BUILD_DIR)/Release/SpaceCommand.app/Contents/MacOS/SpaceCommand
	ditto -c -k --keepParent $(BUILD_DIR)/Release/SpaceCommand.app $(BUILD_DIR)/SpaceCommand.app.zip

BUILD_DIR = $(CURDIR)/build

gen:
	xcodegen generate

build: gen
	@cd scripts && ./sync-version.sh
	@cd scripts && ./bump-build.sh
	xcodebuild -project SpaceCommand.xcodeproj -scheme SpaceCommand -configuration Debug \
		CONFIGURATION_BUILD_DIR=$(BUILD_DIR)/Debug \
		build

run: build
	./build/Debug/SpaceCommand.app/Contents/MacOS/SpaceCommand

clean:
	rm -rf build
	rm -rf SpaceCommand.xcodeproj

bump-major:
	@cd scripts && ./bump-major.sh

bump-minor:
	@cd scripts && ./bump-minor.sh

bump-patch:
	@cd scripts && ./bump-patch.sh

bump-build:
	@cd scripts && ./bump-build.sh
