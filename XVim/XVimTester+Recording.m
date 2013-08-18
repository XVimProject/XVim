//
//  XVimTester+Recording.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/13/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Recording)

- (NSArray*)recording_testcases{
    
    static NSString* text  = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    static NSString* x_result = @"b ccc\n"
                                @"ddd e-e fff\n"
                                @"ggg hhh i_i\n"
                                @"    jjj kkk";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text, 0, 0, @"qallq@a",  text, 4, 0),
            XVimMakeTestCase(text, 0, 0, @"q\"llq@0", text, 4, 0), // Recording int "" register goes into "0
            XVimMakeTestCase(text, 0, 0, @"qbxxq2@b", x_result, 0, 0),
            
            // Record inserted text
            XVimMakeTestCase(@"", 0, 0, @"qaiabc<CR><ESC>q@a", @"abc\nabc\n", 8, 0),
            
            // Record inserted Japanese text
            // TODO: It looks that input japanese through the string expression as below
            //       does not work correctly.
            //       But if you recording typed Japanese input it correctly handled.
            //       Need to fix handling Japanese input as a XVimString
            //XVimMakeTestCase(@"", 0, 0, @"qaiあいう<CR><ESC>q@a", @"あいう\nあいう\n", 8, 0),
            
            // 'q' should not work when executing register with @
            // Copy "qalllq" as a string into register and execute it
            //      The first 'q' will be ignored and "alq" should be executed.
            XVimMakeTestCase(@"qalq", 0, 0, @"\"ayw@a<ESC>", @"qlqalq", 2, 0),
            
            // @x shuold be ignored when executing an register.
            // If we permit to execute reginster while executing a resgister
            // it may go into infinite loop.
            // Actually Vim has this bug(spec?). If Vim execute "a register in which
            // there is "@a" Vim tries to execute "a register again and again.
            // To prohibit this behaviour XVim does not permit execute a register inside executing a register.
            //
            // Text include "@a" and yank it to "a register first.
            // Then execute "a register, which will results in ignoring "@" character when executing.
            // (It means it  executes "laq"
            XVimMakeTestCase(@"l@aq", 0, 0, @"\"ayW@a<ESC>", @"l@qaq", 2, 0),
            nil];
    
}


@end
