//
//  XVimTester+Visual.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/30/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Visual)
- (NSArray*)visual_testcases{
    static NSString* text2 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    static NSString* v_d_result = @"d e-e fff\n"
                                  @"ggg hhh i_i\n"
                                  @"    jjj kkk";
    
    static NSString* V_d_result = @"ggg hhh i_i\n"
                                  @"    jjj kkk";
    
    static NSString* C_v_d_result = @" bbb ccc\n"
                                    @" e-e fff\n"
                                    @" hhh i_i\n"
                                    @"    jjj kkk";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text2, 0,  0, @"vljd", v_d_result, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"Vjd", V_d_result, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljjd", C_v_d_result, 0, 0),
    nil];
}
@end
