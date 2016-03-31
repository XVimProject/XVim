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
#import "DVTFoundation.h"

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

    static NSString* issue_251_result = @"a;a bbb ccc\n"
                                        @"    jjj kkk";

    static NSString* issue_429_result = @"bbb bbb ccc\n";
    
    static NSString* issue_587 = @"test\n"
                                 @"\n"
                                 @"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    
    static NSString* issue_606_result_spaces = @"        aaa bbb ccc\n";
    static NSString* issue_606_result_tabs = @"		aaa bbb ccc\n";


    static NSString* issue_776_text = @"";
    static NSString* issue_776_result = @"\n";
    static NSString* issue_805_text = @"aaaa bbbb cccc dddd eeee ffff gggg\n"
                                      @"hhhh iiii jjjj kkkk llll\n"
                                      @"mmmm nnnn oooo pppp qqqq\n";
    static NSString* issue_805_result = @"hhhh iiii jjjj kkkk llll\n"
                                        @"mmmm nnnn oooo pppp qqqq\n";
    static NSString* issue_809_a_text   = @"aaa bbb\n \nccc\n";
    static NSString* issue_809_a_result = @"aaa b\n \nccc\n";
    static NSString* issue_809_b_text   = @"aaa    \n \nccc\n";
    static NSString* issue_809_b_result = @"aaa  \n \nccc\n";
    static NSString* issue_865 = @"\n" // 0
                                 @"\n" // 1
                                 @"ccc\n";// 2
     
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text1, 12, 0, @"Vjd", issue_251_result , 16, 0),  // Issue #251
            XVimMakeTestCase(text0, 0, 0, @"qadwpq", @"baaa bb ccc\n", 4, 0),  // Issue #396
            XVimMakeTestCase(text1, 24, 0, @":inoremap <lt>C-e> <lt>C-o>$<CR>i<Right><Right><Up><Up><C-e><ESC>", text1 , 10, 0),  // Issue #416
            XVimMakeTestCase(text1, 20, 0, @"yyjp", issue_216_result, 36,0 ),
            XVimMakeTestCase(text1, 4, 0, @"vll<D-x>ibbb<ESC>", text1, 6,0 ),  // Issue #429
            XVimMakeTestCase(text1, 4, 0, @"vll<D-c>", text1, 4,3 ),  // Issue #429 related (Cmd-c should not change selected range)
            XVimMakeTestCase(text0, 4, 0, @"vll<D-c><ESC>0vll<D-v>0", issue_429_result, 0, 0 ),  // Issue #429 related (Cmd-v should overwrite the selection and exit from visual)

            // ^W should not yank
            XVimMakeTestCase(@"abc\n", 2, 0, @"cl<C-w><ESC>p", @"c\n", 0, 0),
            
            XVimMakeTestCase(issue_587, 5, 0, @"j", issue_587, 6, 0 ),  // Issue #587 xvim_sb_init related

            ( [[DVTTextPreferences preferences] useTabsToIndent] ) // check for tab/space indentation
                ? XVimMakeTestCase( text0, 0, 0, @"i<TAB><ESC>.", issue_606_result_tabs, 1, 0 )    // Issue #606. Repeating tab insertion crashes Xcode.
                : XVimMakeTestCase( text0, 0, 0, @"i<TAB><ESC>.", issue_606_result_spaces, 7, 0 ), // Issue #606. Repeating tab insertion crashes Xcode.

            XVimMakeTestCase(issue_776_text, 0, 0, @"O<ESC>", issue_776_result,  0, 0), // Issue #776 crash
            XVimMakeTestCase(issue_805_text, 33, 0, @"dd", issue_805_result, 0, 0), // Issue #805
            XVimMakeTestCase(issue_809_a_text, 5, 0, @"dw", issue_809_a_result, 4, 0),
            XVimMakeTestCase(issue_809_b_text, 5, 0, @"dw", issue_809_b_result, 4, 0),
            
            XVimMakeTestCase(issue_865 , 2, 0, @"gg", issue_865, 0, 0),  // Issue #865
            XVimMakeTestCase(issue_865 , 2, 0, @"1G", issue_865, 0, 0),  // Issue #865
            XVimMakeTestCase(issue_865 , 2, 0, @"2gg", issue_865, 1, 0), // Issue #865
            XVimMakeTestCase(issue_865 , 2, 0, @"2G", issue_865, 1, 0),  // Issue #865
            XVimMakeTestCase(issue_865 , 2, 0, @"G", issue_865, 6, 0),   // Issue #865
            
            XVimMakeTestCase(text0, 0, 0, @":nmap <lt>backspace> l<cr><bs><bs>", text0, 2, 0), // Issue #844 mapping <backspace>
            nil];
    
}


@end
