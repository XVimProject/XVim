XVim
=======

XVim is a Vim plugin for Xcode. The plugin intends to offer a compelling Vim experience without the need to give up any Xcode features.

Support Xcode Versions
=============
We are developing XVim with Xcode 4.6 at the moment, So we recommend you use XVim with XCode 4.6. 

Xcode 5 will be supported (Currently we are working on Xcode5-DP3 to work with XVim. See Issue #402, #404, #405)

INSTALL
=======

 - Download source code and open XVim.xcodeproj with Xcode.
 - Go to "Edit Scheme" and set "Build Configuration" as "Release"
 - (You may need to set "Base SDK" value in Build Settings to "Latest OS X")
 - Build it. It automatically installs the plugin into the correct directory.
 - Restart Xcode. (Make it sure that Xcode proccess is terminated entirely)

Uninstall
=============
Delete the following directory:

    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin

Feature list
=============
See separate [FeatureList.md](https://github.com/JugglerShu/XVim/blob/master/Documents/Users/FeatureList.md)

Bug reports
=============
Unfortunately XVim sometimes crashes Xcode. We are working on eliminating all the bugs, but it's really hard work.
It helps greatly when we have your bug reports, with the following information:
 * Crash information ( Xcode shows threads stack trace when crashes. Copy them. )
 * The operations you did to cause the crash ( series of key strokes or mouse clicks )
 * The text you were manipulating
 * Xcode version 
 * XVim version ( Version number of the revision you built )

There is also a logging feature in XVim. It can be turned on/off with `:set debug` & `:set nodebug`.
By default, it is off; to default to on, just add `:set debug` to your `.xvimrc`.
When logging is on, all key input is logged in `$HOME/.xvimlog`.
This log file is also generally helpful for debugging.

Contributions
=============
Any suggestions, bug reports or feature requests are welcome.
Any pull requests are very much appreciated.
Before you make pull request see Documents/Developers/PullRequest.md

Donations
===========
If you think the plugin is useful, please donate.
Since I do not intend make money from this project, I am directing donations
to the people suffering from the damage of the 2011 Tohoku earthquake and tsunami in Japan.

Please donate directly through the Paypal donation site below, as
this will put more money to good use by reducing the transfer fee.

https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

Since no messages are sent when you donate from the paypal link, you could also write a donation message on
[Message Board]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim ).
I(we) would really appreciate it, and it will really motivate me(us)!

Contributors
============
See contributors page in github repository.
https://github.com/JugglerShu/XVim/contributors

License
============
MIT License

