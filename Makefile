xcodebuild:=xcodebuild -configuration

ifdef BUILDLOG
REDIRECT=>> $(BUILDLOG)
endif

.PHONY: release debug clean clean-release clean-debug uninstall uuid build-test

release: uuid code_unsign
	$(xcodebuild) Release $(REDIRECT)

debug: uuid code_unsign
	$(xcodebuild) Debug $(REDIRECT)


clean: clean-release clean-debug

clean-release:
	$(xcodebuild) Release clean

clean-debug:
	$(xcodebuild) Debug clean


uninstall:
	rm -rf "$(HOME)/Library/Application Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin"

code_unsign:
	@xcode_path=`xcode-select -p`; \
	echo Target Xcode : $${xcode_path}; \
	xcode_version=`defaults read "$${xcode_path}/../Info" CFBundleShortVersionString`; \
	major=`printf '%.0f' $${xcode_version}`; \
	codesign -dv $${xcode_path}/../MacOS/Xcode > /dev/null 2>&1; \
	if [[ $$? == 0 && $${major} -ge 8 ]]; then \
		printf "With your Xcode version $${xcode_version} it is required to remove "; \
		printf "code signature from Xcode to load XVim plugin. "; \
		printf "This may increase security risk since you cannot validate Xcode signature once we remove it. "; \
		printf "Do you want to remove code signature from your Xcode? (y/N)"; \
		read -r -n 1 in; \
		if [[ $$in != "" &&  ( $$in == "y" || $$in == "Y") ]]; then \
			echo ; \
			printf "Close Xcode and press enter."; \
			read -r -n 1 in; \
			$(MAKE) -C Tools/unsign; \
			cp -n $${xcode_path}/../MacOS/Xcode $${xcode_path}/../MacOS/Xcode_orig; \
			printf "The original Xcode binary is backed up to $${xcode_path}/../MacOS/Xcode_orig\n"; \
			Tools/unsign/unsign $${xcode_path}/../MacOS/Xcode $${xcode_path}/../MacOS/Xcode; \
		fi ;\
	fi;

uuid:
	@xcode_path=`xcode-select -p`; \
	uuid=`defaults read "$${xcode_path}/../Info" DVTPlugInCompatibilityUUID`; \
	xcode_version=`defaults read "$${xcode_path}/../Info" CFBundleShortVersionString`; \
	grep $${uuid} XVim/Info.plist > /dev/null ; \
	if [ $$? -ne 0 ]; then \
		printf "XVim hasn't confirmed the compatibility with your Xcode, Version $${xcode_version}\n"; \
		printf "Do you want to compile XVim with support Xcode Version $${xcode_version} at your own risk? (y/N)"; \
		read -r -n 1 in; \
		if [[ $$in != "" &&  ( $$in == "y" || $$in == "Y") ]]; then \
			plutil -insert DVTPlugInCompatibilityUUIDs.0 -string $${uuid} XVim/Info.plist; \
		fi ;\
		printf "\n"; \
	fi ;

# Build with all the available Xcode in /Applications directory
build-test:
	@> build.log; \
    xcode_path=`xcode-select -p`; \
	for xcode in /Applications/Xcode*.app; do \
		sudo xcode-select -s "$$xcode"; \
		echo Building with $$xcode >> build.log; \
		"$(MAKE)" -C . BUILDLOG=build.log; \
	done; \
	sudo xcode-select -s $${xcode_path}; \
