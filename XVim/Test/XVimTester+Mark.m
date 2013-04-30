//
//  XVimTester+Mark.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/30/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Mark)
- (NSArray*)mark_testcases{
    static NSString* text2 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text2, 5,  0, @"majj3l`a", text2, 5, 0),
            XVimMakeTestCase(text2, 5,  0, @"majj3l'a", text2, 0, 0),
    nil];
}
@end
