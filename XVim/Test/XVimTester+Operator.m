//
//  XVimTester+Operator.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/30/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Operator)
- (NSArray*)operator_testcases{
    static NSString* text0 = @"aAa bbb ccc\n";
    
    static NSString* text1 = @"aaa\n"   // 0  (index of each WORD)
                             @"bbb\n"   // 4
                             @"ccc";    // 8
    
    static NSString* text2 = @"aAa bbb ccc";
    
    static NSString* a_result  = @"aAa bbXXXb ccc\n";
    static NSString* a_result2 = @"aAa bbXXXXXXXXXb ccc\n";
    static NSString* a_result3 = @"aXXXaa\n"
                                 @"bbb\n"
                                 @"ccc"; 
    
    static NSString* A_result =  @"aAa bbb cccXXX\n";
    static NSString* A_result2 = @"aAa bbb cccXXXXXXXXX\n";
    static NSString* A_result3 = @"aaaXXX\n"
                                 @"bbb\n"
                                 @"ccc"; 
    
    static NSString* cw_result1 = @"aAa baaa ccc\n";
    static NSString* cw_result2 = @"aAa bbb caaa\n";
    static NSString* cw_result3 = @"aaa\nccc";
    static NSString* cw_result4 = @"aAa bXXXXXXX";
    static NSString* cw_result5 = @"XXX\n"
                                  @"bbb\n"
                                  @"ccc";
    
    static NSString* C_result1 = @"aAa baaa\n";
    static NSString* C_result2 = @"aaaa\n"
                                 @"ccc";
    static NSString* C_result3 = @"aAa baaaaaaa\n";
    static NSString* C_result4 = @"XXX\n"
                                 @"bbb\n"
                                 @"ccc";
    
    static NSString* cc_result1 = @"aaa\n";
    static NSString* cc_result2 = @"aaa\n"
                                  @"ccc";
    static NSString* cc_result3 = @"aaa\n";
    static NSString* cc_result4 = @"aaa\n"
                                  @"bbb\n"
                                  @"ccc";
    
    static NSString* d_result1 = @"a\n"
                                 @"bbb\n"
                                 @"ccc";
    static NSString* d_result2 = @"a\n"
                                 @"ccc";
    static NSString* d_result3 = @"bbb\n"
                                 @"ccc";
    static NSString* d_result4 = @"a\n"
                                 @"bbb\n"
                                 @"ccc";
    static NSString* dw_result2 = @"\n"
                                  @"bbb\n"
                                  @"ccc";
    static NSString* dw_result3 = @"aAa bbb ";
    static NSString* dw_result4 = @"aAa bbb c";
    
    static NSString* D_result1 = @"a\n"
                                 @"bbb\n"
                                 @"ccc";
    static NSString* D_result2 = @"a\n"
                                 @"ccc";
    static NSString* D_result3 = @"a\n"
                                 @"\n"
                                 @"";
    static NSString* D_result4 = @"a\n"
                                 @"bbb\n"
                                 @"ccc";
    
    static NSString* dd_result1 = @"bbb\n"
                                  @"ccc";
    static NSString* dd_result2 = @"ccc";
    static NSString* dd_result3 = @"";
    static NSString* dd_result4 = @"bbb\n"
                                  @"ccc";
    
    static NSString* r_result1 = @"aAa bXb ccc\n";
    static NSString* r_result2 = @"aAa bXXXccc\n";
    static NSString* r_result3 = @"aAa bXXXccc\n";
    static NSString* r_result4 = @"aXa\n"
                                 @"bbb\n"
                                 @"ccc"; 
    static NSString* r_result5 = @"aXa\n"
                                 @"bbb\n"
                                 @"ccc"; 
    
    
    static NSString* yw_result1 = @"aAa aAa bbb ccc\n";
    static NSString* yw_result2 = @"aAa bbb cccccc";
    
    static NSString* oO_text = @"int abc(){\n"  // 0 4
    @"}\n";          // 11
    
    static NSString* oO_result = @"int abc(){\n" // This result may differ from editor setting. This is for 4 spaces for indent.
    @"    \n"      // 11
    @"}\n";
    
    static NSString* guw_result = @"aaa bbb ccc\n";
    static NSString* gUw_result = @"AAA bbb ccc\n";
    static NSString* guu_result = @"aaa bbb ccc\n";
    static NSString* gUU_result = @"AAA BBB CCC\n";
    
    static NSString* tilde_result = @"Aaa bbb ccc\n";
    static NSString* g_tilde_w_result = @"AaA bbb ccc\n";
    
    static NSString* C_o_result = @"abcdefbbb ccc\n";
    static NSString* C_w_result = @"aAa bbb \n";
    static NSString* C_w_result2 = @"aAa bbb c\n";
    //static NSString* C_w_resutl3= @"aaabbb\n"
    //                              @"ccc";
    
    return [NSArray arrayWithObjects:
            // All changes/insertions must be repeated by dot(.)
            // All insertions must set hat(^) mark
            // All changes/insertions must set dot(.) mark
            
            // a
            XVimMakeTestCase(text0, 5,  0, @"aXXX<ESC>"    , a_result ,  8, 0), // aXXX<ESC>
            XVimMakeTestCase(text0, 5,  0, @"3aXXX<ESC>"   , a_result2, 14, 0), // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"aXXX<ESC>.."  , a_result2, 14, 0), // Repeat
            XVimMakeTestCase(text1, 0,  0, @"aXXX<ESC>jj`^", a_result3,  4, 0), // ^ Mark
            XVimMakeTestCase(text1, 0,  0, @"aXXX<ESC>jj`.", a_result3,  3, 0), // . Mark
            
            // A
            XVimMakeTestCase(text0, 5,  0, @"AXXX<ESC>"    , A_result,  13, 0), // AXXX<ESC>
            XVimMakeTestCase(text0, 5,  0, @"3AXXX<ESC>"   , A_result2, 19, 0), // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"AXXX<ESC>.."  , A_result2, 19, 0), // Repeat
            XVimMakeTestCase(text1, 0,  0, @"AXXX<ESC>jj`^", A_result3,  5, 0), // ^ Mark
            XVimMakeTestCase(text1, 0,  0, @"AXXX<ESC>jj`.", A_result3,  5, 0), // . Mark
            
            // c
            XVimMakeTestCase(text0, 5,  0, @"cwaaa<ESC>"    , cw_result1,  7, 0),
            XVimMakeTestCase(text0, 9,  0, @"cwaaa<ESC>"    , cw_result2, 11, 0),
            XVimMakeTestCase(text1, 1,  0, @"2cwaa<ESC>"    , cw_result3,  2, 0), // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"2cwXXX<ESC>.." , cw_result4, 11, 0), // Repeat
            XVimMakeTestCase(text1, 0,  0, @"cwXXX<ESC>jj`^", cw_result5,  2, 0), // ^ Mark
            XVimMakeTestCase(text1, 0,  0, @"cwXXX<ESC>jj`.", cw_result5,  2, 0), // . Mark
            
            // C
            XVimMakeTestCase(text0, 5,  0, @"Caaa<ESC>"     , C_result1,  7, 0),
            XVimMakeTestCase(text1, 1,  0, @"2Caaa<ESC>"    , C_result2,  3, 0), // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"Caaa<ESC>.."   , C_result3, 11, 0), // Repeat
            XVimMakeTestCase(text1, 0,  0, @"CXXX<ESC>jj`^" , C_result4,  2, 0), // ^ Mark
            XVimMakeTestCase(text1, 0,  0, @"CXXX<ESC>jj`." , C_result4,  2, 0), // . Mark
            
            // cc
            XVimMakeTestCase(text0, 5,  0, @"ccaaa<ESC>"     , cc_result1,  2, 0),
            XVimMakeTestCase(text1, 1,  0, @"2ccaaa<ESC>"    , cc_result2,  2, 0), // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"ccaaa<ESC>.."   , cc_result3,  2, 0), // Repeat
            XVimMakeTestCase(text1, 1,  0, @"ccaaa<ESC>jj`^" , cc_result4,  2, 0), // ^ Mark
            XVimMakeTestCase(text1, 1,  0, @"ccaaa<ESC>jj`." , cc_result4,  2, 0), // . Mark
            
            // d
            XVimMakeTestCase(text1, 1, 0, @"dw"    , d_result1, 0, 0),
            XVimMakeTestCase(text1, 1, 0, @"2dw"   , d_result2, 0, 0),    // Numeric arg
            XVimMakeTestCase(text1, 1, 0, @"dw.."  , d_result3, 0, 0), // Repeat
            XVimMakeTestCase(text1, 1, 0, @"dwjj`.", d_result4, 0, 0),    // . Mark
            // dw at the end of line should not delete newline
            XVimMakeTestCase(text1, 0, 0, @"dw", dw_result2, 0, 0),
            // dw at the end of file
            XVimMakeTestCase(text2, 8, 0, @"dw", dw_result3, 7, 0),
            // dvw at the end of file should not delete last character( a little strange behaviour in vim)
            XVimMakeTestCase(text2, 8, 0, @"dvw", dw_result4, 8, 0),
            // TODO: dvw at the end of line should not delete last character( a little strange behaviour in vim)
            
            // D
            XVimMakeTestCase(text1, 1, 0, @"D"     , D_result1, 0, 0),
            XVimMakeTestCase(text1, 1, 0, @"2D"    , D_result2, 0, 0), // Numeric arg
            XVimMakeTestCase(text1, 1, 0, @"Dj.j." , D_result3, 3, 0), // Repeat
            XVimMakeTestCase(text1, 1, 0, @"Djj`." , D_result4, 0, 0), // . Mark
            
            // D for blankline
            // Vim never deletes blankline with D
            // The strange thing is that 2D deletes 2 lines including line below current cursor position.
            // Assume we have 3 empty lines (They haev only \n in each line)
            //  D -> 0 line is deleted
            // 2D -> 2 lines are deleted
            // Because of this strangeness XVim does not support first one.
            // XVim deletes one line when D comes to blankline.
            
            // Test case Vim passes but XVim does not
            // XVimMakeTestCase(@"\n\n" , 0, 0, @"D"  , @"\n\n", 0, 0), // D never delete blank line
            
            // Test XVim passes but not Vim behaviour
            XVimMakeTestCase(@"\n\n" , 0, 0, @"D"  , @"\n", 0, 0),
            
            // 2D (Vim and XVim has same behaviour)
            XVimMakeTestCase(@"\n\n" , 0, 0, @"2D"  , @"", 0, 0),
            
            // dd
            XVimMakeTestCase(text1, 1, 0, @"dd"    , dd_result1, 0, 0),
            XVimMakeTestCase(text1, 1, 0, @"2dd"   , dd_result2, 0, 0), // Numeric arg
            XVimMakeTestCase(text1, 1, 0, @"dd.."  , dd_result3, 0, 0), // Repeat
            XVimMakeTestCase(text1, 1, 0, @"ddjj`.", dd_result4, 0, 0), // . Mark
            
            // y, Y
            XVimMakeTestCase(text0, 0,  0, @"ywP", yw_result1,  3, 0),
            XVimMakeTestCase(text2, 8,  0, @"ywP", yw_result2, 10, 0), // Yank to end of file
            
            // yy
            XVimMakeTestCase(text0, 0,  0, @"ywP", yw_result1,  3, 0),
            
            // r
            XVimMakeTestCase(text0, 5,  0, @"rX",     r_result1, 5, 0),
            XVimMakeTestCase(text0, 5,  0, @"3rX"   , r_result2, 7, 0), // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"rXl.l.", r_result3, 7, 0), // Repeat
            XVimMakeTestCase(text1, 1,  0, @"rXjj`^", r_result4, 2, 0), // ^ Mark
            XVimMakeTestCase(text1, 1,  0, @"rXjj`.", r_result5, 1, 0), // . Mark
            
            /*
            // s, S
            XVimMakeTestCase(text0, 0, 0, @"dw", dw_result, 0, 0),
            XVimMakeTestCase(text0, 5, 0, @"2Caaaa<ESC>", Cw_result1,  8, 0),    // Numeric arg
            XVimMakeTestCase(text0, 5, 0, @"Caaaa<ESC>jj..", Cw_result1,  8, 0), // Repeat
            XVimMakeTestCase(text0, 5, 0, @"2Caaaa<ESC>", Cw_result1,  8, 0),    // ^ Mark
            XVimMakeTestCase(text0, 5, 0, @"2Caaaa<ESC>", Cw_result1,  8, 0),    // . Mark
            
            // x, X
            XVimMakeTestCase(text0, 0, 0, @"dw", dw_result, 0, 0),
            XVimMakeTestCase(text0, 5,  0, @"2Caaaa<ESC>", Cw_result1,  8, 0),    // Numeric arg
            XVimMakeTestCase(text0, 5,  0, @"Caaaa<ESC>jj..", Cw_result1,  8, 0), // Repeat
            XVimMakeTestCase(text0, 5,  0, @"2Caaaa<ESC>", Cw_result1,  8, 0),    // ^ Mark
            XVimMakeTestCase(text0, 5,  0, @"2Caaaa<ESC>", Cw_result1,  8, 0),    // . Mark
             */
            
            // gu, gU
            XVimMakeTestCase(text0, 0,  0, @"guw", guw_result, 0, 0),
            XVimMakeTestCase(text0, 0,  0, @"gUw", gUw_result, 0, 0),
            XVimMakeTestCase(text0, 4,  0, @"guu", guu_result, 0, 0),
            XVimMakeTestCase(text0, 4,  0, @"gUU", gUU_result, 0, 0),
            
            // ~, g~
            XVimMakeTestCase(text0, 0,  0,     @"~~",     tilde_result,   2, 0),
            XVimMakeTestCase(text0, 0,  0, @"~~hh~~",            text0,   2, 0),
            XVimMakeTestCase(text0, 0,  0,    @"g~w", g_tilde_w_result,   0, 0),
            
            // o, O
            XVimMakeTestCase(oO_text,  4, 0, @"o<ESC>", oO_result, 14, 0),
            XVimMakeTestCase(oO_text, 11, 0, @"O<ESC>", oO_result, 14, 0),
            
            // Insert and Ctrl-o
            XVimMakeTestCase(text0,  0, 0, @"iabc<C-o>dwdef<ESC>", C_o_result, 5, 0),
            
            // Insert and Ctrl-w
            XVimMakeTestCase(text0, 11, 0, @"a<C-w><ESC>", C_w_result, 7, 0),
            XVimMakeTestCase(text0, 11, 0, @"i<C-w><ESC>", C_w_result2, 7, 0),
            // XVimMakeTestCase(text1, 4 , 0, @"i<C-w><ESC>", C_w_result3, 2, 0), // C-w should delete LF but not works currently
            nil];
    
}
@end
