//
//  XVimEditorArea.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDEEditorAreaHook.h"
#import "IDEKit.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVimCommandLine.h"
#import "XVimWindow.h"
#import "DVTKit.h"
#import "XVim.h"

@implementation IDEEditorAreaHook
/**
 * IDEEditorArea is a area including primary editor and assistant editor and debug area (The view right of the navigator)
 * This class hooks IDEEditorArea and does some works.
 * "viewDidInstall" is called when the view setup is done ( as far as I saw the behaviour ).
 * This class has private instance variable named "_editorAreaAutoLayoutView" which is the view
 * contains source code editores and border view between editors and debug area.
 * We insert command line view between editors and debug area.
 * And also to handle all the input to editors we insert XVimWindow object into this view as invisible view.
 * All the input to the editors (DVTSourceTextView) or command line view is forward to XVimWindow class.
 *
 * IDEEdiatorArea exists in every Xcode tabs so if you have 4 tabs in a Xcode window there are 4 command line and XVimWindow views we insert.
 **/

+(void)hook{
    Class c = NSClassFromString(@"IDEEditorArea");
    
    [Hooker hookMethod:@selector(viewDidInstall) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(viewDidInstall) ) keepingOriginalWith:@selector(viewDidInstall_)];
}

- (void)viewDidInstall{
    IDEEditorArea* base = (IDEEditorArea*)self;
    NSView* layoutView;
    [base viewDidInstall_];
    object_getInstanceVariable(self, "_editorAreaAutoLayoutView", (void**)&layoutView); // The view contains editors and border view
    
    // Check if we already have command line in the _editorAreaAutoLayoutView.
    XVimCommandLine* cmd = [XVimCommandLine associateOf:layoutView];
    if( nil == cmd ){
        // We do not have command line yet.
        cmd = [[[XVimCommandLine alloc] init] autorelease];
		[[XVim instance] setCommandLine:cmd];
        [layoutView addSubview:cmd];
		
        // This notification is to resize command line view according to the editor area size.
        [[NSNotificationCenter defaultCenter] addObserver:cmd selector:@selector(didFrameChanged:) name:NSViewFrameDidChangeNotification  object:layoutView];
        if( [[layoutView subviews] count] > 0 ){
            // This is a little hacky but first object in the subview is "border" view.
            DVTBorderedView* border = [[layoutView subviews] objectAtIndex:0];
            // We need to know if border view is hidden or not to place editors and command line correctly.
            [border addObserver:cmd forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
            //NSView* view = [[layoutView subviews] objectAtIndex:0];
            
        }
    }
    
}

@end
