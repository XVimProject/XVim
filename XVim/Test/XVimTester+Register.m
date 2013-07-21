//
//  XVimTester+Register.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/6/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Register)
- (NSArray*)register_testcases{
    static NSString* text  = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    
    static NSString* reg0_result =  @"a;a bbb ccc\n"
                                    @"a;a bbb ccc\n"
                                    @"ggg hhh i_i\n"
                                    @"    jjj kkk";
    
    static NSString* delete_result = @";;; bbb ccc\n"  // 0  4  8
                                     @"ddd e-e fff\n"  // 12 16 20
                                     @"ggg hhh i_i\n"  // 24 28 32
                                     @"    jjj kkk";   // 36 40 44
    
    static NSString* blackhole_result = @"a;a bbb ccc\n"  // 0  4  8
                                        @"ggg hhh i_i\n"  // 24 28 32
                                        @"    jjj kkk";   // 36 40 44
    
    
    static NSString* dot_result1 = @"bb ccc\n"
                                   @"ddd e-e fff\n"
                                   @"ggg hhh i_i\n"
                                   @"    jjj kkk";
    
    return [NSArray arrayWithObjects:
            // Operation using registers
            XVimMakeTestCase(text, 0, 0, @"\"adw\"aP", text, 0, 0), // Cut and paste
            XVimMakeTestCase(text, 12, 0, @"\"bdw\"ady\"bP", text, 15, 0), // use 'a' and 'b' register
            
            // Numbered registers
            // "0
            XVimMakeTestCase(text, 0, 0, @"yyjddk\"0P", reg0_result, 0, 0), // Yank stores "0 and delete does not affect it
            
            // Numbered register rotation with delete/change
            XVimMakeTestCase(text, 0, 0, @"dwdwdl\"2P\"2P\"2P", delete_result, 0, 0), // Yank stores "0 and delete does not affect it
            
            // Blackhole register
            // "_dd never affect registers (including numbered register rotation)
            // Delete 2 lines but 2nd deletion is for blackhole
            XVimMakeTestCase(text, 0, 0, @"dd\"_dd\"_p\"1P", blackhole_result, 0, 0), // Yank stores "0 and delete does not affect it
            
            // Repeat(.)
            XVimMakeTestCase(@"aaa bbb ccc", 0, 0, @"iabc<ESC>b.", @"abcabcaaa bbb ccc", 2, 0),
            XVimMakeTestCase(@"aaa bbb ccc", 0, 0, @"dw.", @"ccc", 0, 0),
            // Numeric arg should be ignored when . with numeric arg
            XVimMakeTestCase(text , 0, 0, @"2x3.", dot_result1, 0, 0),
            
            // Repeat by @@
            XVimMakeTestCase(@"aaa bbb ccc", 0, 0, @"qallq@a2@@", @"aaa bbb ccc", 8, 0),
            
            nil];
}

@end
