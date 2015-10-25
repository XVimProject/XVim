
xcodebuild:=xcodebuild -configuration


release:
	$(xcodebuild) Release

debug:
	$(xcodebuild) Debug


clean: clean-release clean-debug

clean-release:
	$(xcodebuild) Release clean

clean-debug:
	$(xcodebuild) Debug clean


uninstall:
	rm -rf "$(HOME)/Library/Application Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin"

