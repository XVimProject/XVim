//
//  XVimTester+ExCmd.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/3/13.
//
//
#import "XVimTester.h"

@implementation XVimTester (ExCmd)
- (NSArray*)excmd_testcases{
    
    static NSString* text2 = @"ddd\n"
                             @"111\n"
                             @"aaa\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n";
    
    static NSString* sort_result1 =
                                    @"\n"
                                    @"111\n"
                                    @"111\n"
                                    @"XXX\n"
                                    @"aaa\n"
                                    @"ddd\n"
                                    @"uuu\n"
                                    @"xxx\n";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text2, 0,  0, @"VG:sort<CR>", sort_result1, 0, 0),
    nil];
}
@end
