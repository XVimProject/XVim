
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

  Any pull requests are very much appreciated. Before you make a pull request see [Make a Pull Request](Documents/Developers/PullRequest.md)

Watch the videos mentioned earlier for a full tutorial on developing, debugging and testing XVim. Here is a very simple guide to get you started.

### Debugging
  1. Make sure you have Xcode.app installed at /Applications/Xcode.app, if that's true just open XVim.xcodeproj and Run (CMD + R). You can ignore the rest steps.
  2. If you have Xcode installed at a different path, follow these steps.
  3. Open XVim.xcodeproj
  4. Got to Edit Scheme... => Run => Executable => Other => Choose The Xcode.app you installed to.
  5. Run (CMD + R)

### Run Unit Tests
  1. In your .xvimrc, add a line "set debug", which tells XVim to run in debug mode.
  2. Open XVim.xcodeproj, a debug instance of Xcode shows up.
  3. In the debug Xcode instance, create a random small disposable project (say HelloWorld.xcodeproj) if you have don't this already.
  4. Open HelloWorld.xcodeproj using debug Xcode instance.
  5. Go to XVim menu, there should be an item "test categories"
  6. Choose a category to run
  7. A separate window shows up and unit tests are run inside that window.
  8. Results will be shown when all the tests in that category are completed.
