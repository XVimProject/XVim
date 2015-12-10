xcodebuild:=xcodebuild -configuration

.PHONY: release debug clean clean-release clean-debug uninstall uuid

release: uuid
	$(xcodebuild) Release

debug: uuid
	$(xcodebuild) Debug


clean: clean-release clean-debug

clean-release:
	$(xcodebuild) Release clean

clean-debug:
	$(xcodebuild) Debug clean


uninstall:
	rm -rf "$(HOME)/Library/Application Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin"

uuid:
	@xcode_path=`xcode-select -p`; \
	uuid=`defaults read "$${xcode_path}/../Info" DVTPlugInCompatibilityUUID`; \
	xcode_version=`defaults read "$${xcode_path}/../Info" CFBundleShortVersionString`; \
	grep $${uuid} XVim/Info.plist > /dev/null ; \
	if [ $$? -ne 0 ]; then \
		printf "XVim hasn't been confirmed the compatibility with your Xcode Version $${xcode_version}\n"; \
		printf "Do you want to compile XVim with support Xcode Version $${xcode_version} at your own risk? (y/N)"; \
		read -r -n 1 in; \
		if [[ $$in != "" &&  ( $$in == "y" || $$in == "Y") ]]; then \
			plutil -insert DVTPlugInCompatibilityUUIDs.0 -string $${uuid} XVim/Info.plist; \
		fi ;\
		printf "\n"; \
	fi ;
