//
//  XVimEditorArea.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEditorArea.h"
#import "IDEEditorArea.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVimCommandLine.h"
#import "XVimWindow.h"

@implementation XVimEditorArea
+(void)hook{
    Class c = NSClassFromString(@"IDEEditorArea");
    [Hooker hookMethod:@selector(viewDidInstall) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(viewDidInstall) ) keepingOriginalWith:@selector(viewDidInstall_)];
}

- (void)viewDidInstall{
    IDEEditorArea* base = (IDEEditorArea*)self;
    NSView* layoutView;
    [base viewDidInstall_];
    object_getInstanceVariable(self, "_editorAreaAutoLayoutView", (void**)&layoutView);    
    XVimCommandLine* cmd = (XVimCommandLine*)[layoutView viewWithTag:XVIM_CMDLINE_TAG]; // This tag is also used for command line
    if( nil == cmd ){
        cmd = [[[XVimCommandLine alloc] init] autorelease];
        [layoutView addSubview:cmd];
        [[NSNotificationCenter defaultCenter] addObserver:cmd selector:@selector(didFrameChanged:) name:NSViewFrameDidChangeNotification  object:layoutView];
        if( [[layoutView subviews] count] > 0 ){
            NSView* editorView = [[layoutView subviews] objectAtIndex:0];
            [editorView addObserver:cmd forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
        }
    }
    NSView* window = [layoutView viewWithTag:XVIM_TAG];
    if( nil == window ){
        XVimWindow* window = [[[XVimWindow alloc] init] autorelease];
        window.commandLine = cmd;
        cmd.commandField.delegate = window;
        [layoutView addSubview:window];
    }
}

@end
