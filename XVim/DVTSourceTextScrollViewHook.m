//
//  XVimSourceTextScrollView.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/27/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "DVTSourceTextScrollViewHook.h"
#import "DVTSourceTextScrollView.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVimStatusLine.h"

@implementation DVTSourceTextScrollViewHook
+(void)hook{
    Class c = NSClassFromString(@"DVTSourceTextScrollView");
    
    // Hook setSelectedRange:
    [Hooker hookMethod:@selector(viewDidMoveToSuperview) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(viewDidMoveToSuperview) ) keepingOriginalWith:@selector(viewDidMoveToSuperview_)];
}

- (void)viewDidMoveToSuperview{
    // I do not like use this method to insert status line.
    // But this is easier.
    // Idealy we should hook IDESourceCodeEditor and IDEComparisonEditor respectively.
    // They are view controllers for source code editors.
    // Their view structers are a little different so we have to write code to layout the views for each of them.
    // Maybe later.
    DVTSourceTextScrollView* base = (DVTSourceTextScrollView*)self;
    [base viewDidMoveToSuperview_];
    // Add status line
    NSView* container = [self superview];
    if( [container viewWithTag:XVIM_STATUSLINE_TAG] == nil ){
        [container setPostsFrameChangedNotifications:YES];
        XVimStatusLine* status = [[[XVimStatusLine alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease];
        [[NSNotificationCenter defaultCenter] addObserver:status selector:@selector(didContainerFrameChanged:) name:NSViewFrameDidChangeNotification object:container];
        [container addSubview:status];
        [status layoutStatus:container];
    }
}

// I tried to hook this method to install status line but did not work
- (id)initWithFrame:(NSRect)frameRect{
    DVTSourceTextScrollView* base = (DVTSourceTextScrollView*)self;
    base = [base initWithFrame:frameRect];
    
    [Logger traceView:self depth:0];
    return (DVTSourceTextScrollViewHook*)base;
}
@end
