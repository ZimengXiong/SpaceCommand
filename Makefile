.PHONY: gen build run clean

BUILD_DIR = $(CURDIR)/build

gen:
	xcodegen generate

build: gen
	xcodebuild -project SpaceCommand.xcodeproj -scheme SpaceCommand -configuration Debug \
		CONFIGURATION_BUILD_DIR=$(BUILD_DIR)/Debug \
		build

run: build
	open $(BUILD_DIR)/Debug/SpaceCommand.app

clean:
	rm -rf build
	rm -rf SpaceCommand.xcodeproj
