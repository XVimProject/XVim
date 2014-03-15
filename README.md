<div align="right">
<a href="https://github.com/JugglerShu/XVim/blob/master/README_jp.md">[日本語版]</a>
</div>

# XVim
  XVim is a Vim plugin for Xcode. The plugin intends to offer a compelling Vim experience without the need to give up any Xcode features.

#### Announcement
  For Xcode 5.1 : Use the latest develop branch.

  [Google Group for XVim developers](https://groups.google.com/d/forum/xvim-developers) has been created.
  
  This group is for XVim developers and testers(reporters).
  If you are interested in helping XVim project join the group.
  Just testing new release and reporting problem is great help for us. Join the group casually.

## Support Xcode Versions
  - Xcode4.6
  - Xcode5

## INSTALL
 - Download source code(See also "Branches and Releases" section) and open XVim.xcodeproj with Xcode.
 - Select an appropriate Scheme for your Xcode version
    - XVim for Xcode4 must be built with Xcode4.6
    - XVim for Xcode5 must be built with Xcode5
 - Select "Edit Scheme" and set "Build Configuration" as "Release"
 - Build it. It automatically installs the plugin into the correct directory.
 - Restart Xcode. (Make it sure that Xcode proccess is terminated entirely)

## Branches and Releases
 XVim has several branches and releases. Usually you only need to download one of 'releases' and use it.
 Here is an explanation about each release and branch.
 
 - Releases(tags) : Releases are tags on master branch. All the code and documents on these tags are well arranged. Usual XVim user should use one of releases.
 - master : Most stable branch. Critical bug fixes and stable feature developed in 'develop' branch are merged into 'master'. If you find a critical bug in a release, try latest 'master' branch.
 - develop : New features and non critical bug fixes are merged into this branch. If you want experimental features use this branch.

 Any other branches are temporary branches to develop features or bug fixes which will be merged into 'develop' branch after all.
 Any pull requests should be made to 'develop' branch.

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

## Bug issue handling 

  Reported bugs are handled following order.

  1. Confirm if the bug reproduce and the issue labeled as 'Bug'
  2. Fix the bug in 'develop' branch
  3. Confirm the fix by the reporter
  4. The issue is labeled 'Done'
  5. Confirm that the fix does not make another side effect.
  6. Merged into 'master'
  7. The issue is closed.

  This order is only applied to 'Bug' issues.

## Contributions
  Any suggestions, bug reports or feature requests are welcome.
  
  If you want to add a feature or fix bugs by yourself the following videos are good help for you.
 - [How to get debug log](http://www.youtube.com/watch?v=50Bhu8setlc)
 - [How to debug XVim](http://www.youtube.com/watch?v=AbC6f86VW9A)
 - [How to write a test case](http://www.youtube.com/watch?v=kn-kkRTtRcE)

  Any pull requests are very much appreciated. Before you make a pull request see [Make a Pull Request](https://github.com/JugglerShu/XVim/blob/master/Documents/Developers/PullRequest.md)

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

