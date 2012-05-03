#!/usr/bin/ruby

XcodePath = "/Developer/Applications/Xcode.app"
LibraryPaths = ["/Contents/Frameworks/IDEFoundation.framework",
				"/Contents/Frameworks/IDEKit.framework",
				"/Contents/SharedFrameworks/DVTFoundation.framework",
				"/Contents/SharedFrameworks/DVTKit.framework",
				"/Contents/PlugIns/IDESourceEditor.ideplugin"
				]
OutDir = "XcodeClasses/"

LibraryPaths.each{|file|
	output = OutDir + File.basename(file, ".*")
	puts `class-dump -I -C "DVT.*|IDE.*" #{XcodePath}#{file} > #{output}.h`
}
