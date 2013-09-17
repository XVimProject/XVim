//
//  XVimTester+Motion.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/30/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Motion)
- (NSArray*)motion_testcases{
    
    static NSString* text1 = @"aaa\n"   // 0  (index of each WORD)
                             @"bbb\n"   // 4
                             @"ccc";    // 8
    
    static NSString* text2 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    static NSString* text3 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e\n"      // 12 16
                             @"ggg hhh i_i\n"  // 20 24 28
                             @"    jjj kkk";   // 32 36 40
    
    static NSString* text4 = @"a;a {bb ccc\n"  // 0  4  8
                             @"d(d e-) ddd\n"  // 12 16 20
                             @"g[g }hh i_i\n"  // 24 28 32
                             @"    jj] kkk";   // 36 40 44
    
    return [NSArray arrayWithObjects:
            // b, B
            XVimMakeTestCase(text2,  6, 0,  @"b", text2,  4, 0),
            XVimMakeTestCase(text2, 14, 0, @"3b", text2,  4, 0),
            XVimMakeTestCase(text2,  4, 0,  @"B", text2,  0, 0),
            XVimMakeTestCase(text2, 27, 0, @"3B", text2, 16, 0),
            
            // e, E
            XVimMakeTestCase(text2, 16, 0,  @"e", text2, 17, 0),
            XVimMakeTestCase(text2, 17, 0, @"3e", text2, 26, 0),
            XVimMakeTestCase(text2, 16, 0,  @"E", text2, 18, 0),
            XVimMakeTestCase(text2, 16, 0, @"3E", text2, 26, 0),
            
            // f, F
            XVimMakeTestCase(text2,  0, 0,  @"fc", text2,  8, 0),
            XVimMakeTestCase(text2,  0, 0, @"2fc", text2,  9, 0),
            XVimMakeTestCase(text2, 18, 0,  @"Fd", text2, 14, 0),
            XVimMakeTestCase(text2, 18, 0, @"2Fd", text2, 13, 0),
            XVimMakeTestCase(text2, 24, 0, @"4fi", text2, 24, 0), // error case
            
            // g, G
            XVimMakeTestCase(text2, 44, 0,  @"gg", text2,  8, 0),
            XVimMakeTestCase(text2, 44, 0, @"3gg", text2, 32, 0),
            XVimMakeTestCase(text2,  8, 0, @"9gg", text2, 44, 0),
            XVimMakeTestCase(text2,  4, 0,   @"G", text2, 40, 0),
            XVimMakeTestCase(text2, 44, 0,  @"3G", text2, 32, 0),
            XVimMakeTestCase(text2,  8, 0,  @"9G", text2, 44, 0),
            
            // h,j,k,l, <space>
            XVimMakeTestCase(text1, 0, 0,   @"l", text1, 1, 0),
            XVimMakeTestCase(text1, 0, 0, @"10l", text1, 2, 0),
            XVimMakeTestCase(text1, 0, 0,   @"j", text1, 4, 0),
            XVimMakeTestCase(text1, 0, 0, @"10j", text1, 8, 0),
            XVimMakeTestCase(text1, 4, 0,   @"k", text1, 0, 0),
            XVimMakeTestCase(text1, 1, 0,   @"h", text1, 0, 0),
            XVimMakeTestCase(text1, 0, 0,   @"<Space>", text1, 1, 0),
            XVimMakeTestCase(text1, 0, 0, @"10<Space>", text1, 2, 0),
            
            // t, T
            XVimMakeTestCase(text2,  0, 0,  @"tc", text2,  7, 0),
            XVimMakeTestCase(text2,  0, 0, @"2tc", text2,  8, 0),
            XVimMakeTestCase(text2, 18, 0,  @"Td", text2, 15, 0),
            XVimMakeTestCase(text2, 18, 0, @"2Td", text2, 14, 0),
            XVimMakeTestCase(text2, 24, 0, @"4ti", text2, 24, 0), // error case
            
            // w, W
            XVimMakeTestCase(text2, 0, 0,  @"w", text2,  1, 0),
            XVimMakeTestCase(text2, 0, 0, @"4w", text2,  8, 0),
            XVimMakeTestCase(text2, 0, 0,  @"W", text2,  4, 0),
            XVimMakeTestCase(text2, 0, 0, @"4W", text2, 16, 0),
            
            // 0, $, ^
            XVimMakeTestCase(text2, 10, 0,   @"0", text2,  0, 0),
            XVimMakeTestCase(text2,  0, 0,   @"$", text2, 10, 0),
            XVimMakeTestCase(text2, 44, 0,   @"^", text2, 40, 0),
            XVimMakeTestCase(text2, 44, 0, @"10^", text2, 40, 0), // Number does not affect caret
            XVimMakeTestCase(text2, 36, 0,   @"^", text2, 40, 0),
            XVimMakeTestCase(text2, 36, 0,   @"_", text2, 40, 0),
            XVimMakeTestCase(text2, 32, 0,  @"2_", text2, 40, 0),
            
            // %
            XVimMakeTestCase(text4, 0, 0, @"%", text4, 28, 0),
            XVimMakeTestCase(text4,12, 0, @"%", text4, 18, 0),
            XVimMakeTestCase(text4,16, 0, @"%", text4, 13, 0),
            XVimMakeTestCase(text4,24, 0, @"%", text4, 42, 0),
            XVimMakeTestCase(text4,40, 0, @"%", text4, 25, 0),
            XVimMakeTestCase(text4,26, 0, @"%", text4,  4, 0),
            XVimMakeTestCase(text4, 8, 0, @"%", text4,  8, 0),
            
            // numericArg + %
            // Go to the position of specified percentage down from head
            // Must keep current column position
            //XVimMakeTestCase(text4,12, 0, @"2%",text4,  4, 0), // Not supported correctly
            
            
            // +, -, <CR>
            XVimMakeTestCase(text2, 28, 0,  @"+", text2, 40, 0),
            XVimMakeTestCase(text2, 16, 0, @"2+", text2, 40, 0),
            XVimMakeTestCase(text2, 40, 0,  @"-", text2, 24, 0),
            XVimMakeTestCase(text2, 40, 0, @"2-", text2, 12, 0),
            XVimMakeTestCase(text2, 28, 0, @"<CR>", text2, 40, 0),
            XVimMakeTestCase(text2, 16, 0,@"2<CR>", text2, 40, 0),
            
            // Motion with k,l should remember column position
            XVimMakeTestCase(text3, 30, 0,  @"k", text3, 18, 0),
            XVimMakeTestCase(text3, 30, 0,  @"kk",text3, 10, 0),
            
            // H,M,L
            //TODO: Implement test for H,M,L. These needs some special test check method since we have to calc the height of the view.
            
            // Arrows( left,right,up,down )
            
            // Home, End, DEL
            
            // Motion type enforcing(v,V, Ctrl-v)
            
            // Searches (/,?,n,N,*,#) are implemented in XVimTester+Search.m
            
            // , ; (comma semicolon) for f F
            XVimMakeTestCase(text2, 0, 0,  @"2fb;", text2, 6, 0),
            XVimMakeTestCase(text2, 0, 0,  @"fb2;", text2, 6, 0),
            XVimMakeTestCase(text2, 0, 0,  @"2fb,", text2, 4, 0),
            XVimMakeTestCase(text2, 0, 0, @"3fb2,", text2, 4, 0),
            
            XVimMakeTestCase(text2, 8, 0, @"2Fb;", text2, 4, 0),
            XVimMakeTestCase(text2, 8, 0, @"Fb2;", text2, 4, 0),
            XVimMakeTestCase(text2, 8, 0, @"2Fb,", text2, 6, 0),
            XVimMakeTestCase(text2, 8, 0, @"3Fb2,", text2, 6, 0),
            
            // , ; (comma semicolon) for t T
            
        nil];
}
@end
