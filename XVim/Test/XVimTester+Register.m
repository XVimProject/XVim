//
//  XVimTester+Register.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/6/13.
//
//

#import "XVimTester+Register.h"

@implementation XVimTester (Register)
- (NSArray*)register_testcases{
    static NSString* text  = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    
    /*
     static NSString* reg0_result =  @"a;a def ccc\n"
                                    @"a;a def ccc\n"
                                    @"ggg hhh i_i\n"
                                    @"    jjj kkk";
    
    static NSString* imap_result2 = @"a;a abc ccc\n"  // 0  4  8
                                    @"ddd e-e fff\n"  // 12 16 20
                                    @"ggg hhh i_i\n"  // 24 28 32
                                    @"    jjj kkk";   // 36 40 44
    
     */
    return [NSArray arrayWithObjects:
            // Operation using registers
            XVimMakeTestCase(text, 0, 0, @"\"adw\"aP", text, 0, 0), // Cut and paste
            XVimMakeTestCase(text, 12, 0, @"\"bdw\"ady\"bP", text, 15, 0), // use 'a' and 'b' register
            
            // Numbered registers
            // "0
            // XVimMakeTestCase(text, 0, 0, @"yyjddk\"0P", reg0_result, 0, 0), // Yank stores "0 and delete does not affect it
            
            
            // Recording
            
            // Repeat(.)
            
            
            nil];
}

@end
