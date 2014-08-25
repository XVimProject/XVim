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

task :xcode4, [:reqs]  do |t, args|
  if isInstalled?
    puts "XVim already installed, Use `rake uninstall` to uninstall XVim"
  else
    reqs = args[:reqs]
    conf = getConfiguration(reqs)
    sh "xcodebuild -scheme 'XVim for Xcode4' -configuration '#{conf}'"
  end
end

task :xcode56, [:reqs]  do |t, args|
  if isInstalled?
    puts "XVim already installed, Use `rake uninstall` to uninstall XVim"
  else
    reqs = args[:reqs]
    conf = getConfiguration(reqs)
    puts "Building and Installing XVim for Xcode 5 and 6"
    sh "xcodebuild -scheme 'XVim for Xcode5 and 6' -configuration '#{conf}'"
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

task :default do
  puts "Which XCode do you have?"
  puts "1. XCode 4"
  puts "2. XCode 5 or 6"
  print "Write your answer here (1 or 2): "
  choicestr = readline
  choicenum = Integer(choicestr)
  if choicenum == 1
    Rake::Task[:xcode4].invoke()
  elsif choicenum == 2
    Rake::Task[:xcode56].invoke()
  else
    puts "Wrong Choice. Please run `rake` again."
  end
end

