//
//  XVimTest.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import "XVimTester.h"
#import "XVimTestCase.h"
#import <objc/runtime.h>
#import "Logger.h"
#import "IDEKit.h"
#import "XVimKeyStroke.h"
#import "XVimUtil.h"


@implementation XVimTester

- (NSArray*)createTestCases{
    // Text Definitions
    static NSString* text1 = @"aaa\n"   // 0  (index of each WORD)
                             @"bbb\n"   // 4
                             @"ccc";    // 8
    
    static NSString* text2 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i";   // 24 28 32
    
    // Test Cases
    NSArray* testArray = [NSArray arrayWithObjects:
                          // Motions
                          // b, B
                          XVimMakeTestCase(text2,  6, 0,  @"b", text2,  4, 0),
                          XVimMakeTestCase(text2, 14, 0, @"3b", text2,  4, 0),
                          XVimMakeTestCase(text2,  4, 0,  @"B", text2,  0, 0),
                          XVimMakeTestCase(text2, 27, 0, @"3B", text2, 16, 0),
                          
                          // w, W
                          XVimMakeTestCase(text2, 0, 0,  @"w", text2,  1, 0),
                          XVimMakeTestCase(text2, 0, 0, @"4w", text2,  8, 0),
                          XVimMakeTestCase(text2, 0, 0,  @"W", text2,  4, 0),
                          XVimMakeTestCase(text2, 0, 0, @"4W", text2, 16, 0),
                          
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
                          
                          // h,j,k,l
                          XVimMakeTestCase(text1, 0, 0,   @"l", text1, 1, 0),
                          XVimMakeTestCase(text1, 0, 0,   @"j", text1, 4, 0),
                          XVimMakeTestCase(text1, 4, 0,   @"k", text1, 0, 0),
                          XVimMakeTestCase(text1, 1, 0,   @"h", text1, 0, 0),
                          XVimMakeTestCase(text1, 0, 0, @"10l", text1, 2, 0),
                          XVimMakeTestCase(text1, 0, 0, @"10j", text1, 9, 0),
                          
                          
                          // Operations
                          nil
                          ];
    return testArray;
}

- (void)runTest{
    // Create Test Cases
    NSArray* testArray = [self createTestCases];
    
    // Alert Dialog to confirm current text will be deleted.
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This deletes text held in current source text view. Proceed?"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSInteger b = [alert runModal];
    
    // Run test for all the cases
    NSMutableString* result = [[[NSMutableString alloc] init] autorelease];
    if( b == NSAlertFirstButtonReturn ){
        // test each
        for( NSUInteger i = 0; i < testArray.count; i++ ){
            XVimTestCase* c = [testArray objectAtIndex:i];
            BOOL r = [(XVimTestCase*)[testArray objectAtIndex:i] run];
            [result appendFormat:@"%03lu %@ %@\n", i, r ? @"PASS":@"FAIL", c.description];
        }
    }
   
    alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:result];
    [alert runModal];
}

@end
