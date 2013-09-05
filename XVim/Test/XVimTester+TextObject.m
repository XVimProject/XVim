//
//  XVimTester+TextObject.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/30/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (TextObject)

- (NSArray*)textobject_testcases{
    static NSString* text_object0 = @"aaa(aaa)aaa";
    static NSString* text_object1 = @"bbb\"bbb\"bbb";
    static NSString* text_object2 = @"ccc{ccc}ccc";
    static NSString* text_object3 = @"ddd[ddd]ddd";
    static NSString* text_object4 = @"eee'eee'eee";
    static NSString* text_object5 = @"fff<fff>fff";
    static NSString* text_object6 = @"ggg`ggg`ggg";
    static NSString* text_object7 = @"hhh hhh hhh";
    
    // Text object results with delete
    static NSString* text_object_i_result0 = @"aaa()aaa";
    static NSString* text_object_a_result0 = @"aaaaaa";
    static NSString* text_object_i_result1 = @"bbb\"\"bbb";
    static NSString* text_object_a_result1 = @"bbbbbb";
    static NSString* text_object_i_result2 = @"ccc{}ccc";
    static NSString* text_object_a_result2 = @"cccccc";
    static NSString* text_object_i_result3 = @"ddd[]ddd";
    static NSString* text_object_a_result3 = @"dddddd";
    static NSString* text_object_i_result4 = @"eee''eee";
    static NSString* text_object_a_result4 = @"eeeeee";
    static NSString* text_object_i_result5 = @"fff<>fff";
    static NSString* text_object_a_result5 = @"ffffff";
    static NSString* text_object_i_result6 = @"ggg``ggg";
    static NSString* text_object_a_result6 = @"gggggg";
    static NSString* text_object_i_result7 = @"hhh  hhh";
    static NSString* text_object_a_result7 = @"hhh hhh";
    
    // Text object results with yank
    static NSString* text_object_yi_result0 = @"aaaaaa(aaa)aaa";
    static NSString* text_object_ya_result0 = @"(aaa)aaa(aaa)aaa";
    
    // Text Objects(TODO: with Numeric Arg)
    return [NSArray arrayWithObjects:
        // (), b
        XVimMakeTestCase(text_object0, 5, 0, @"di(", text_object_i_result0 , 4, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"di)", text_object_i_result0 , 4, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"da(", text_object_a_result0 , 3, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"da)", text_object_a_result0 , 3, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"dib", text_object_i_result0 , 4, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"dab", text_object_a_result0 , 3, 0),
            
        XVimMakeTestCase(text_object0, 5, 0, @"yi(0P", text_object_yi_result0 , 2, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"yi)0P", text_object_yi_result0 , 2, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"ya(0P", text_object_ya_result0 , 4, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"ya)0P", text_object_ya_result0 , 4, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"yib0P", text_object_yi_result0 , 2, 0),
        XVimMakeTestCase(text_object0, 5, 0, @"yab0P", text_object_ya_result0 , 4, 0),
            
        // "
        XVimMakeTestCase(text_object1, 5, 0, @"di\"", text_object_i_result1 , 4, 0),
        XVimMakeTestCase(text_object1, 5, 0, @"da\"", text_object_a_result1 , 3, 0),
        
        // {}, B
        XVimMakeTestCase(text_object2, 5, 0, @"di{", text_object_i_result2 , 4, 0),
        XVimMakeTestCase(text_object2, 5, 0, @"di}", text_object_i_result2 , 4, 0),
        XVimMakeTestCase(text_object2, 5, 0, @"da{", text_object_a_result2 , 3, 0),
        XVimMakeTestCase(text_object2, 5, 0, @"da}", text_object_a_result2 , 3, 0),
        XVimMakeTestCase(text_object2, 5, 0, @"diB", text_object_i_result2 , 4, 0),
        XVimMakeTestCase(text_object2, 5, 0, @"daB", text_object_a_result2 , 3, 0),
        
        // []
        XVimMakeTestCase(text_object3, 5, 0, @"di[", text_object_i_result3 , 4, 0),
        XVimMakeTestCase(text_object3, 5, 0, @"di]", text_object_i_result3 , 4, 0),
        XVimMakeTestCase(text_object3, 5, 0, @"da[", text_object_a_result3 , 3, 0),
        XVimMakeTestCase(text_object3, 5, 0, @"da]", text_object_a_result3 , 3, 0),
        
        // '
        XVimMakeTestCase(text_object4, 5, 0, @"di'", text_object_i_result4 , 4, 0),
        XVimMakeTestCase(text_object4, 5, 0, @"da'", text_object_a_result4 , 3, 0),
        
        // <>
        XVimMakeTestCase(text_object5, 5, 0, @"di<", text_object_i_result5 , 4, 0),
        XVimMakeTestCase(text_object5, 5, 0, @"di>", text_object_i_result5 , 4, 0),
        XVimMakeTestCase(text_object5, 5, 0, @"da<", text_object_a_result5 , 3, 0),
        XVimMakeTestCase(text_object5, 5, 0, @"da>", text_object_a_result5 , 3, 0),
        
        // `
        XVimMakeTestCase(text_object6, 5, 0, @"di`", text_object_i_result6 , 4, 0),
        XVimMakeTestCase(text_object6, 5, 0, @"da`", text_object_a_result6 , 3, 0),
        
        // w
        XVimMakeTestCase(text_object7, 5, 0, @"diw", text_object_i_result7 , 4, 0),
        XVimMakeTestCase(text_object7, 5, 0, @"daw", text_object_a_result7 , 4, 0),
    nil];
}
@end
