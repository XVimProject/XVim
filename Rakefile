require 'rake'
require 'fileutils'

$plugin_filename ="#{ENV['HOME']}/Library/Application Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin"

def isDebug?(reqs)
  return (reqs and reqs.contain? "debug")
end

def getConfiguration(reqs)
  if isDebug? reqs
    return "Debug"
  else
    return "Release"
  end
end

def isInstalled?()
 return File.exists? $plugin_filename
end


def getXcodeVersion
  return Integer(`xcodebuild -version`.split(' ')[1].split('.')[0])
end

task :xcode56, [:reqs]  do |t, args|
  if getXcodeVersion == 5 or getXcodeVersion == 6
    if isInstalled?
      puts "XVim already installed, Use `rake uninstall` to uninstall XVim"
    else
      reqs = args[:reqs]
      conf = getConfiguration(reqs)
      puts "Building and Installing XVim for Xcode 5 and 6"
      sh "xcodebuild -scheme 'XVim for Xcode5 and 6' -configuration '#{conf}'"
    end
  else
    sh "ERROR: Wrong Xcode version. You need Xcode 5 or 6 to use XVim."
   end
end

task :clean do
  puts "Cleaning"
  sh "xcodebuild clean"
end

task :uninstall do
  if isInstalled?
    print "#{$plugin_filename} found, Uninstalling..."
    FileUtils.rm_r $plugin_filename
    print " [done]\n"
  else
    puts "WARNING: #{$plugin_filename} not found. Have you really installed XVim?"
  end
end

task :pluginuuid do
  plugin_uuid = `defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID`
  puts "UUID:#{plugin_uuid}"
end

task :default => [:xcode56]
