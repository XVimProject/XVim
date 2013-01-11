XVim
=======

XVim is a Vim plugin for Xcode. The plugin intends to offer a compelling Vim experience without the need to give up any Xcode features.

(I'm looking for a job now. See HIREME.md.... Sorry if this is inappropriate to be here)

INSTALL
=======

From Installer Package
--------

Download a daily build from http://programming.jugglershu.net/xvim . Usually the latest one is the best choice for you.

(Sorry, daily build is not working correctly. If you want really updated version see "From Source Code" section)

(For Xcode 4.2 for Snow Leopard you can not use the installer package. See below to install from source code.)

Install it without changing the installation directory and then restart Xcode. That's it!

From Source Code
-----------------

Download source code and build XVim.xcodeproj. 
It automatically builds and installs the plugin into the correct directory.

If you want to build with Xcode 4.2 for Snow Leopard, you will first need to change the build settings.
Open the project editing page, and set "Mac OS X Deployment Target" to "10.6".

After a build, to use XVim, you should restart Xcode.

Uninstall
=============
Delete the following directory:

    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin

Feature list
=============
See separate [FeatureList.md](https://github.com/JugglerShu/XVim/blob/master/Documents/Users/FeatureList.md)

Support Xcode Versions
=============
We are developing XVim with Xcode 4.3 at the moment, So we recommend you use XVim with XCode 4.3. 
Though, it should work on 4.2 too and we want to support that as much as possible.
So if you have any problems with Xcode 4.2, feel free to create a new issue.

Bug reports
=============
Unfortunately XVim sometimes crashes Xcode. We are working on eliminating all the bugs, but it's really hard work.
It helps greatly when we have your bug reports, with the following information:
 * Crash information ( Xcode shows threads stack trace when crashes. Copy them. )
 * The operations you did to cause the crash ( series of key strokes or mouse clicks )
 * The text you were manipulating
 * Xcode version ( 4.3 or 4.2 ... )
 * XVim version ( Version number of the revision you built or the date of the daylybuild package )

There is also a logging feature in XVim. It can be turned on/off with `:set debug` & `:set nodebug`.
By default, it is off; to default to on, just add `:set debug` to your `.xvimrc`.
When logging is on, all key input is logged in `$HOME/.xvimlog`.
This log file is also generally helpful for debugging.

Contributions
=============
Any suggestions, bug reports or feature requests are welcome.
Any pull requests are very much appreciated.
If you are interested in contributing, I can assign you as a collaborator of this repository.

For Japanese Users/Developers (日本の開発者のみなさまへ）
==================================================
このプラグインは世界中で使えるようにと、基本的に英語で開発したり、コミュニケーションを取ったり
しています。ただし、それを強制するものではありません。
できるだけ多くの方に使っていただきたい、参加していただきたいのですが、日本のユーザー/開発者の中には英語に
抵抗のある方も少なからずいるのではなかと思っています。
ぜひ日本語でリクエストを出したり、コメントを書いてください。必要な場合はこちらで英訳します。
あと、英語の意味分からないなどある場合も聞いてください。
(What I wrote here is to tell Japanese users/developers NOT TO HESITATE to communicate in Japanese in this project. I'll translate them if needed.)

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

このプロジェクト、プラグインがよいと思われましたら寄付をいただけると非常にうれしいです。
寄付はすべて東日本大震災の復興のためにそのまま寄付をいたします。
手数料などがかかってしまいますので、賛同いただける方は以下から直接寄付いただければと思います。

https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

この場合、こちらにメッセージなどが来ることはありませんので、
メッセージを[Message Board]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim )にいただけると、開発のモチベーションにつながります。

Contributors
============
See contributors page in github repository.
https://github.com/JugglerShu/XVim/contributors


