//
//  XVimTester+Jump.m
//  XVim
//
//  Created by pebble8888 on 2014/10/12.
//
//

#import "XVimTester.h"

@implementation XVimTester (Jump)
- (NSArray*)jump_testcases{
    static NSString* text1 = @"aa\n"   // 0
                             @"bb\n"   // 3
                             @"cc\n";  // 6
    static NSString* text2 = @"aa\n"   // 0
                             @"aa\n"   // 3
                             @"aa\n"   // 6
                             @"bb\n"   // 9
                             @"bb\n"   // 12
                             @"bb\n"   // 15
                             @"cc\n"   // 18
                             @"cc\n"   // 21
                             @"cc\n";  // 24
    static NSString* text3 = @"aaa bbb.\n"  // 0
                             @"ccc ddd.\n"; // 9
    return @[
             XVimMakeTestCase(text1, 1,  0, @"3G``"       , text1,  1, 0), // [num]G
             XVimMakeTestCase(text1, 1,  0, @"3G''"       , text1,  0, 0), // [num]G
             
             XVimMakeTestCase(text1, 1,  0, @"3G<C-o>"    , text1,  1, 0), // [num]G
             XVimMakeTestCase(text1, 7,  0, @"gg<C-o>"    , text1,  7, 0), // gg
             XVimMakeTestCase(text1, 1,  0, @"50%<C-o>"   , text1,  1, 0), // [num]%
             XVimMakeTestCase(text1, 1,  0, @"G<C-o>"     , text1,  1, 0), // G
             XVimMakeTestCase(text1, 7,  0, @"H<C-o>"     , text1,  7, 0), // H
             XVimMakeTestCase(text1, 1,  0, @"M<C-o>"     , text1,  1, 0), // M
             XVimMakeTestCase(text1, 1,  0, @"L<C-o>"     , text1,  1, 0), // L
             
             XVimMakeTestCase(text2, 1,  0, @"/aa<CR><C-o>" , text2,  1, 0), // /
             XVimMakeTestCase(text2, 1,  0, @"/aa<CR>n<C-o>", text2,  3, 0), // n
             XVimMakeTestCase(text2, 1,  0, @"?aa<CR><C-o>",  text2,  1, 0), // ?
             XVimMakeTestCase(text2, 1,  0, @"?aa<CR>n<C-o>", text2,  0, 0), // n
             
             XVimMakeTestCase(text2, 1,  0, @"*<C-o>" ,       text2,  1, 0), // *
             XVimMakeTestCase(text2, 1,  0, @"#<C-o>",        text2,  1, 0), // #
             
             XVimMakeTestCase(text3, 1,  0, @")<C-o>"       , text3,  1, 0), // )
             XVimMakeTestCase(text3, 1,  0, @"(<C-o>"       , text3,  1, 0), // (
             XVimMakeTestCase(text3, 1,  0, @"}<C-o>"       , text3,  1, 0), // (
             XVimMakeTestCase(text3, 1,  0, @"{<C-o>"       , text3,  1, 0), // (
             
             XVimMakeTestCase(text2, 24,  0, @"ggi<ESC>jjjgi<ESC><C-o>", text2,  24, 0), // gi : gi doesn't change jump list
             
             XVimMakeTestCase(text1, 7,  0, @"makk`a<C-o>"  , text1,  1, 0), // `a
             XVimMakeTestCase(text1, 7,  0, @"makk'a<C-o>"  , text1,  1, 0), // 'a
             
             // In original vim if 'startofline' not set, keep the same column. default value is on.
             XVimMakeTestCase(text1, 0, 0, @":set nostartofline<CR>", text1, 0, 0),
             XVimMakeTestCase(text1, 1,  0, @"2G3G``"       , text1,  4, 0), // ``    XVim behaviour
             XVimMakeTestCase(text1, 1,  0, @"2G3G````"     , text1,  7, 0), // ````  XVim behaviour

             XVimMakeTestCase(text1, 0, 0, @":set startofline<CR>", text1, 0, 0),
             XVimMakeTestCase(text1, 1,  0, @"2G3G``"       , text1,  3, 0), // ``   original vim behaviour
             XVimMakeTestCase(text1, 1,  0, @"2G3G````"     , text1,  6, 0), // ```` original vim behaviour

             XVimMakeTestCase(text1, 1,  0, @"2G3G''"       , text1,  3, 0), // ''
             XVimMakeTestCase(text1, 1,  0, @"2G3G''''"     , text1,  6, 0), // ''
             
             XVimMakeTestCase(text1, 1,  0, @"/bb<CR>/cc<CR><C-o>"            , text1,  3, 0), // <C-o>
             XVimMakeTestCase(text1, 1,  0, @"/bb<CR>/cc<CR><C-o><C-o>"       , text1,  1, 0), // <C-o>
             XVimMakeTestCase(text1, 1,  0, @"/bb<CR>/cc<CR><C-o><C-o>3G<C-o>", text1,  1, 0), // <C-o>
             
             // Re-Indent key bind need to be cleared in Xcode Preferences to pass these test.
             XVimMakeTestCase(text1, 1,  0, @"/bb<CR>/cc<CR><C-o><C-i>"       , text1,  6, 0), // <C-i>
             XVimMakeTestCase(text1, 1,  0, @"/bb<CR>/cc<CR><C-o><C-o><C-i><C-i>", text1,  6, 0), // <C-i>
             
    ];
}

@end
