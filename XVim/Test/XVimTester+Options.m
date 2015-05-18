//
//  XVimTester+Options.m
//  XVim
//
//  Created by Paul Williamson on 18/05/2015.
//
//

#import "XVimTester.h"

@implementation XVimTester (Options)

- (NSArray *)options_testcases{
    static NSString* text1 = @"aaa BBB ccc";

    return [NSArray arrayWithObjects:
            // make sure ignore case is off
            XVimMakeTestCase(text1, 0, 0, @":set noignorecase<CR>", text1, 0, 0),
            // search should fail
            XVimMakeTestCase(text1, 0, 0, @"/bbb<CR>", text1, 0, 0),
            // toggle ignore case
            XVimMakeTestCase(text1, 0, 0, @":set ignorecase!<CR>", text1, 0, 0),
            // search should succeed
            XVimMakeTestCase(text1, 0, 0, @"/bbb<CR>", text1, 4, 0), // shouldnt this be 4,3 range?
            // toggle ignore case
            XVimMakeTestCase(text1, 0, 0, @":set ignorecase!<CR>", text1, 0, 0),
            // search should fail again
            XVimMakeTestCase(text1, 0, 0, @"/bbb<CR>", text1, 0, 0),
            // make sure string inverting doesn't crash Xcode
            XVimMakeTestCase(text1, 0, 0, @":set guioptions! rb", text1, 0, 0),
            nil];
}

@end
