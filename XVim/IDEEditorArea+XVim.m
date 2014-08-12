//
//  IDEEditorArea+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>
#import "IDEEditorArea+XVim.h"
#import "XVimWindow.h"

static const char *KEY_WINDOW       = "xvimwindow";

@implementation IDEEditorArea (XVim)

- (XVimWindow *)xvimWindow
{
    return objc_getAssociatedObject(self, KEY_WINDOW);
}

- (NSView *)textViewArea
{
    NSView *layoutView;

    // The view contains editors and border view
    object_getInstanceVariable(self, "_editorAreaAutoLayoutView", (void**)&layoutView);
    return layoutView;
}

- (DVTBorderedView *)debuggerBarBorderedView
{
    DVTBorderedView *border;

    // The view contains editors and border view
    object_getInstanceVariable(self, "_debuggerBarBorderedView", (void**)&border);
    return border;
}

- (void)setupXVim
{
    XVimWindow *xvim = [[XVimWindow alloc] initWithIDEEditorArea:self];
    NSView *layoutView = [self textViewArea];
    XVimCommandLine *cmd = xvim.commandLine;

    [layoutView addSubview:cmd];

    // This notification is to resize command line view according to the editor area size.
    [[NSNotificationCenter defaultCenter] addObserver:cmd
                                             selector:@selector(didFrameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:layoutView];
    if (layoutView.subviews.count > 0) {
        DVTBorderedView *border = [self debuggerBarBorderedView];

        // We need to know if border view is hidden or not to place editors and command line correctly.
        [border addObserver:cmd forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    }

    objc_setAssociatedObject(self, KEY_WINDOW, xvim, OBJC_ASSOCIATION_RETAIN);
    [xvim release];
}

- (void)teardownXVim
{
    XVimCommandLine *cmd = self.xvimWindow.commandLine;
    DVTBorderedView *border = [self debuggerBarBorderedView];

    [border removeObserver:cmd forKeyPath:@"hidden"];
    [[NSNotificationCenter defaultCenter] removeObserver:cmd];
}

@end
