#!/usr/bin/ruby

require 'shellwords'

XcodePath = `xcode-select -p`.chomp + "/"
ContentDir = XcodePath + "../"
XcodeVersion = `defaults read #{ContentDir}version.plist CFBundleShortVersionString`.chomp
OutputDir = (ARGV[0] == nil ? "Xcode#{XcodeVersion}" : ARGV[0]) + "/"

`mkdir -p #{Shellwords.escape(OutputDir)}`

def is_framework(path)
    return true if /\.framework$/ =~ path 
    return true if /\.ideplugin$/ =~ path 
    return false
end

def list_frameworks(directory, rel_dir, &block)
    Dir.foreach(directory){ |x|
        path = File.join(directory, x)
        if x == "." or x == ".."
            next
        elsif is_framework(path)
            block.call(path, rel_dir)
        elsif File.directory?(path)
                list_frameworks(path, rel_dir + "/" + x, &block)
        end
    }
end

list_frameworks(ContentDir, ""){|path, rel_dir|
    puts "dumping #{path}..."
    targetDir = OutputDir + rel_dir;
    `mkdir -p #{Shellwords.escape(targetDir)}`
    targetFile = targetDir + "/" + File.basename(path, ".*") + ".h"
	`class-dump #{path} > #{targetFile}`
}
