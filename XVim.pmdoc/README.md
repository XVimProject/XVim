
# About the Location of the product
This package maker project assumes that the product (which means XVim.xcplugin here)
is at 

    build/release/XVim.xcplugin (relative to pmdoc)

Xcode default build setting make a product into somewhat specified by DrivedData dir which
is not under XVim project directory.
To make Xcode output a product into under "build" dir you have to specify the following setting from Xcode menu.

    File - Project Settings -> "Advanced" in "Build" Tab -> Select "Locations Specified by Targets" for "Build Location"

Build XVim with "release" configuration make XVim plugin into the directory above.


Know better solution? Let me know please!
( I want to make XVim installer package automatically when build the project by Xcode )
