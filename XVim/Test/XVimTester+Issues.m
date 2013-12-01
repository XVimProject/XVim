//
//  XVimTester+Issues.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/24/13.
//
//

/**
 * This test category is named "Issues" and test cases here
 * ensure the issues we solved does not happen again.
 * Because the problem issues in github reports mainly some complex input
 * like "yank while recording into a register" such test case does not fits
 * in any simple category (Operation or Recording in this case but we can not 
 * tell which is suitable...)
 * So I made this category.
 * You do not need to put test cases related to any issues here if it is has more
 * suitable category.
 * But please write issue number as a comment next to the test case.
 **/

#import "XVimTester.h"

@implementation XVimTester (Issues)
- (NSArray*)issues_testcases{
    
    static NSString* text0 = @"aaa bbb ccc\n";
    static NSString* text1 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    static NSString* issue_216_result = @"a;a bbb ccc\n" 
                                        @"ddd e-e fff\n" 
                                        @"ggg hhh i_i\n" 
                                        @"ddd e-e fff\n" 
                                        @"    jjj kkk";  
    
    static NSString* issue_429_result = @"bbb bbb ccc\n";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text0, 0, 0, @"qadwpq", @"baaa bb ccc\n", 4, 0),  // Issue #396
            XVimMakeTestCase(text1, 24, 0, @":inoremap <lt>C-e> <lt>C-o>$<CR>i<Right><Right><Up><Up><C-e><ESC>", text1 , 10, 0),  // Issue #416
            XVimMakeTestCase(text1, 20, 0, @"yyjp", issue_216_result, 36,0 ),
            XVimMakeTestCase(text1, 4, 0, @"vll<D-x>ibbb<ESC>", text1, 6,0 ),  // Issue #429
            XVimMakeTestCase(text1, 4, 0, @"vll<D-c>", text1, 4,3 ),  // Issue #429 related (Cmd-c should not change selected range)
            XVimMakeTestCase(text0, 4, 0, @"vll<D-c><ESC>0vll<D-v>0", issue_429_result, 0, 0 ),  // Issue #429 related (Cmd-v should overwrite the selection and exit from visual)

            // ^W should not yank
            XVimMakeTestCase(@"abc\n", 2, 0, @"cl<C-w><ESC>p", @"c\n", 0, 0),
            
            nil];
    
}


@end
