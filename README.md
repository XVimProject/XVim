# XVim
  XVim is a Vim plugin for Xcode. The plugin intends to offer a compelling Vim experience without the need to give up any Xcode features.

#### Announcement
  Google Group for XVim developers has been created.
  https://groups.google.com/d/forum/xvim-developers
  This group is for XVim developers and testers(reporters).
  In this group we are going to talk about the direction of XVim such as

  - What we should implement next
  - How to design XVim
  - Any suggestions for XVim
  - Annoucement for testers before a release of XVim
  - and so on

  If you are interested in helping XVim project join the group.
  Just testing new release and reporting problem is great help for us. Join the group casually.

## Support Xcode Versions
  - Xcode4.6
  - Xcode5

## INSTALL
 - Download source code(of one of releases) and open XVim.xcodeproj with Xcode.
 - Select an appropriate Scheme for your Xcode version
    - XVim for Xcode4 must be built with Xcode4.6
    - XVim for Xcode5 must be built with Xcode5
 - Select "Edit Scheme" and set "Build Configuration" as "Release"
 - Build it. It automatically installs the plugin into the correct directory.
 - Restart Xcode. (Make it sure that Xcode proccess is terminated entirely)

## Releases
 See releases in github. There are explanations for each releases. Use appropreate one.

## Uninstall
  Delete the following directory:

    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin

## Feature list
  See separate [FeatureList.md](https://github.com/JugglerShu/XVim/blob/master/Documents/Users/FeatureList.md)

## Bug reports
  Unfortunately XVim sometimes crashes Xcode. We are working on eliminating all the bugs, but it's really hard work.
  It helps greatly when we have your bug reports, with the following information:

   * Crash information ( Xcode shows threads stack trace when crashes. Copy them. )
   * The operations you did to cause the crash ( series of key strokes or mouse clicks )
   * The text you were manipulating
   * Xcode version 
   * XVim version ( Version number of the revision you built )
  
  When it is hard to solve a problem with information above, take debug log according to the following movie please.
  
  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)

  We appreciate if you write test case for the bug. Read "Write test" section in Documents/Developsers/PullRequest.md how to write test case. You do not need to update any source code but just write 7 items explained there in an issue you create.
 

## Contributions
  Any suggestions, bug reports or feature requests are welcome.
  Any pull requests are very much appreciated.
  Before you make pull request see Documents/Developers/PullRequest.md

## Donations
  If you think the plugin is useful, please donate.
  Since I do not intend make money from this project, I am directing donations
  to the people suffering from the damage of the 2011 Tohoku earthquake and tsunami in Japan.

  Please donate directly through the Paypal donation site below, as
  this will put more money to good use by reducing the transfer fee.

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  Since no messages are sent when you donate from the paypal link, you could also write a donation message on
  [Message Board]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim ).
  I(we) would really appreciate it, and it will really motivate me(us)!

## Contributors
  See contributors page in github repository.
  https://github.com/JugglerShu/XVim/contributors

## License
  MIT License

