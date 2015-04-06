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
    
    static NSString* yank_result1 = @"ddd\n"
                             @"111\n"
                             @"aaa\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"111\n"
                             @"aaa\n"
                             @"XXX\n"
                             @"\n"
                             @"111\n";
    
    static NSString* shift_result1 = @"ddd\n"
                             @"        111\n"
                             @"        aaa\n"
                             @"        XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n";
    
    static NSString* copy_result1 =
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"ddd\n"
                             @"111\n"
                             @"aaa\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n";
    
    static NSString* copy_result2 =
                             @"ddd\n"
                             @"111\n"
                             @"aaa\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n";
    
    static NSString* delete_result1 =
                             @"ddd\n"
                             @"111\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n";
    
    static NSString* move_result1 =
                             @"aaa\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"ddd\n"
                             @"111\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n";
    
    static NSString* move_result2 =
                             @"ddd\n"
                             @"111\n"
                             @"uuu\n"
                             @"\n"
                             @"111\n"
                             @"aaa\n"
                             @"XXX\n"
                             @"xxx\n";
    
    static NSString* move_result3 =
                             @"ddd\n"
                             @"XXX\n"
                             @"xxx\n"
                             @"uuu\n"
                             @"111\n"
                             @"aaa\n"
                             @"\n"
                             @"111\n";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text2, 0,  0, @"VG:sort<CR>", sort_result1, 0, 0),

            //SHIFTS
            // the following test cases assume that Xcode indent in the preference is 4 spaces
            //shift right x2
            XVimMakeTestCase(text2, 0,  0, @":2,4>><CR>", shift_result1, 12, 0),
            //single address, shift right x2
            XVimMakeTestCase(text2, 0,  0, @":2>><CR>:3>><CR>:4>><CR>", shift_result1, 36, 0),
            //shift right x1, shift right x3, shift left x4 = no text change
            XVimMakeTestCase(text2, 0,  0, @":2,4><CR>:2,4>>><CR>:2,4<<<<<CR>", text2, 4, 0),

    	    //DELETE
            XVimMakeTestCase(text2, 0,  0, @":3,5d<CR>", delete_result1, 8, 0),
            //single line address using offset from current line via -/+
            XVimMakeTestCase(text2, 0,  0, @":+4d<CR>:-2d<CR>:.d<CR>", delete_result1, 8, 0),
            
            //YANK
            //test yank and . as cursor location
            XVimMakeTestCase(text2, 0,  0, @"jjj:2,.y<CR>jjp", yank_result1, 24, 0),
            //backwards range
            XVimMakeTestCase(text2, 0,  0, @"jjj:.,2y<CR>jjp", yank_result1, 24, 0),
            //named mark as address
            XVimMakeTestCase(text2, 0,  0, @"jmajj:'a,.y<CR>jjp", yank_result1, 24, 0),
            //single address
            XVimMakeTestCase(text2, 0,  0, @"jjjjj:2yank<CR>p:3y<CR>p:4y<CR>p", yank_result1, 32, 0),

            //COPY
            //copy (t)
            XVimMakeTestCase(text2, 0,  0, @":2,4t6<CR>", yank_result1, 32, 0),
            //copy, before first line
            XVimMakeTestCase(text2, 0,  0, @":4,6copy0<CR>", copy_result1, 8, 0),
            //copy (t), after last line
            XVimMakeTestCase(text2, 0,  0, @":4,6t$<CR>", copy_result2, 37, 0),
            
            //MOVE
            //move before first line
            XVimMakeTestCase(text2, 0,  0, @":3,5m0<CR>", move_result1, 8, 0),
            //move after last line
            XVimMakeTestCase(text2, 0,  0, @":3,5m$<CR>", move_result2, 25, 0),
            //move in the middle
            XVimMakeTestCase(text2, 0,  0, @":2,3m6<CR>", move_result3, 20, 0),
            
            //FAILURE TESTS
            //move target in the middle of the source address
            XVimMakeTestCase(text2, 0,  0, @":3,5m4<CR>", text2, 0, 0),
            //copy target is unknown mark
            XVimMakeTestCase(text2, 0,  0, @":3,5t's<CR>", text2, 0, 0),
            //trailing characters in move target
            XVimMakeTestCase(text2, 0,  0, @":3,5m6f<CR>", text2, 0, 0),
            //trailing characters in shift
            XVimMakeTestCase(text2, 0,  0, @":3,5>>f<CR>", text2, 0, 0),
    nil];
}
@end
