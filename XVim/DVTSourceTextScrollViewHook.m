//
//  XVimSourceTextScrollView.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/27/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "DVTSourceTextScrollViewHook.h"
#import "DVTKit.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVimStatusLine.h"

@implementation DVTSourceTextScrollViewHook
+(void)hook{
    //Class c = NSClassFromString(@"DVTSourceTextScrollView");
}


// I tried to hook this method to install status line but did not work
// This is not currently 
- (id)initWithFrame:(NSRect)frameRect{
    /*
    DVTSourceTextScrollView* base = (DVTSourceTextScrollView*)self;
    base = [base initWithFrame:frameRect];
    
    [Logger traceView:self depth:0];
    return (DVTSourceTextScrollViewHook*)base;
     */
    return nil;
}
@end
