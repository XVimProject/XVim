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
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text0, 0, 0, @"qadwpq", @"baaa bb ccc\n", 4, 0),  // Issue #396
            XVimMakeTestCase(text1, 24, 0, @":inoremap <lt>C-e> <lt>C-o>$<CR>i<Right><Right><Up><Up><C-e><ESC>", text1 , 10, 0),  // Issue #416
            nil];
    
}


@end
