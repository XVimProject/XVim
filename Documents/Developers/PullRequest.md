# How to make a pull request

This file explains some rules I would like you to obey when you make a pull request.
This keeps the code clean and maintainable.

## Basic steps to make a pull request
Here is overveiw of steps to meke a pull request.

 - Fork the XVim repository (And clone it to your local)
 - Checkout 'Develop' branch.  (You must not work on Master)
 - Create your feature branch  (Optional but recommended) 
 - Add/Fix features
 - Run/Write tests and confirm all the tests are passed
 - Write FeatureList.md (if needed)
 - Make a pull request to 'Develop' branch

The first step is just a general operation on git/github. So I do not explain it here.
I explain rest of the items in detail below.


## Check out 'Develop' branch
We have 'Develop' branch to work on daily development. So use it.
'Develop' branch is a kind of buffer to the 'Master' branch.
When I feel everything(including other pull requsts) is fine I merge 'Develop' into 'Master'


## Create your feature branch  (Optional but recommended) 
Make a branch for your modification. This is for who want to add/fix more than one features.
Think that you made a fix for feature A, and made a pull request.
I may want to keep it from merging for a week but you started to add another fix for feature B on the same branch you made a pull request from.
When I want to merge the fix for feature A I have to find which commit to merge
This is the reason for the recommendation.


# Add/Fix features
This is the main part. This is really up to you.
There is no such big rule to obey to write code now.
See Documents/Developers/DevGuide.md to how to modify/debug XVim.


# Run/Write tests and confirm all the test are passed
XVim has automatic testing feature. It ensures that your code modification did not break
any other features. Unfortunately since XVim codes are complex it is really likely to happen that you braek other features.
And also you must create a test case for your modification to ensure it is not broken by further modification.


## Run test
You should run test not only the end of your code modification but regulerly.
To run tests select "Run Test" from the Xcode menu "XVim -> Run Test" (This shows up only when
you write "set debug" in .xvimrc file. You need to restart Xcode if you have not written it.).

This runs all the tests (Be careful that it deletes current text content and may even save it. Make a dummy project and run it on that text. )

Then you see the result in a newly created window. 
If you find some non pass test cases in the list it means you broke something.
See "Description" column to know which command did not work correctly. "Message" column may help you to find the reason why it is broken.  You may be need to see XVim/Test/XVimTester+xxx.h file to find out what is the actual test case which was not passed. See "How to write test" section to know how to read test cases. 


## write test
XVim has a test runner which executes set of test cases.
You usually need to write one or some test case to provide to the test runner. There are 2 steps: Write test case, Add it to array of test cases.


### Create one test case object
One test case consits of 7 items.

 - Initial text
 - Initial insertion point (index starts from 0)
 - Initial selected range (0 if no selection)
 - Command to execute
 - Expected text as a result
 - Expected insertion point as a result (index starts from 0)
 - Expected selected range as a result (0 if no selection)

You can provide these items into XVimMakeTestCase macro to create test case.
For example, following is a test case suitable for 'l' (move right).

    XVimMakeTestCase(@"abc", 0, 0, @"l", @"abc", 1, 0)

This means on the text @"abc" and insertion piont index 0 (at 'a' in this case) with no selection (0 length selection),
command @"l" should resuts in the same text @"abc" and insertion point at index 1 (at 'b' in this case) with no selection.
Here is another example.

    XVimMakeTestCase(@"abc\nabc", 4, 0, @"iabc<CR><ESC>dd", @"abc\nabc", 4, 0,)

This starts from text:

    abc
    abc

And the insertion point is on second 'a'.
Command @"iabc<CR><ESC>dd" should insert "abc\n" and dd should delete the last line (3rd line since we inserted "abc\n") and insertion point should go to ato the second 'a' again.


### Add a test case to the array of test cases
Here is simple explanation to add a test case.
 - Find XVimTester+xxxx.m file to add a test case (xxxx is name of category. Find one which is suitable for your test case)
 - Write XVimMakeTestCase macro into the array there.
 - (You can make NSString object above the array to use in the macro. It will keep the array more readable.)

XVim has XVimTester class and its categories named XVimTester(xxx).
All the test cases goes into one of ites categories.
(The word 'category' here means both Object-c category and test case category. I used objective-c category feature to categorize test case categories.)

So assume that you made a test case for @"l" (motion) command. So you shoul find which category this test case should go in.
There is XVimTester(Motion) category in XVimTester+Motion.m file.
You can see there is only one method named (NSArray*)motion_testcases.
In this method you can see some NSString object and array of XVimMakeTestCase macros.
What you have to do is just adding the XVimMakeTestCase macor into the array.
NSString objects are for using in the macro. Since some test case need long and multiple line of initial text(or result text) to do this makes the test cases more readable.

If you can not find a suitable category your test case should go in you can make another category. See XVimTester.m file to see how to create a category.


# Write FeatureList.md (if needed)
FeatureList.md manages currently supported features by XVim. If the modification you made is just an bug fix you may not need to modify the file.
If you add or modify behaviour of a feature you must modify the file too.

The file is at Documents/Users/FeatureList.md


# Make pull request to 'Develop' branch
So you are now ready to make a pull request. Confirm following again please.
 - You are working on 'Develop' or branch from 'Develop'
 - You made a test case for your modification
 - All the tests(not only yours) are passed
 - Modified FeatureList.md (if needed)

After you push your modification to your github repository make a pull request from the branch you worked on to XVim 'Develop' branch.


Thank you for you help. I really appreceate it!
