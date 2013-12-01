//
//  IDEEditorArea+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>
#import "IDEEditorArea+XVim.h"
#import "NSObject+XVimAdditions.h"
#import "XVimWindow.h"

static const char *KEY_WINDOW = "xvimwindow";

/**
 * IDEEditorArea is a area including primary editor and assistant editor and debug area (The view right of the navigator)
 * This class hooks IDEEditorArea and does some works.
 * "viewDidInstall" is called when the view setup is done ( as far as I saw the behaviour ).
 * This class has private instance variable named "_editorAreaAutoLayoutView" which is the view
 * contains source code editores and border view between editors and debug area.
 * We insert command line view between editors and debug area.
 *
 * IDEEdiatorArea exists in every Xcode tabs so if you have 4 tabs in a Xcode window there are 4 command line and XVimWindow views we insert.
 */
@implementation IDEEditorArea (XVim)

+ (void)xvim_initialize
{
    if (self == [IDEEditorArea class]) {
        [self xvim_swizzleInstanceMethod:@selector(viewDidInstall)
                                    with:@selector(xvim_viewDidInstall)];
        [self xvim_swizzleInstanceMethod:@selector(primitiveInvalidate)
                                    with:@selector(xvim_primitiveInvalidate)];
    }
}

- (XVimWindow *)xvim_window
{
    return objc_getAssociatedObject(self, KEY_WINDOW);
}

- (NSView *)_xvim_editorAreaAutoLayoutView
{
    NSView *layoutView;

    // The view contains editors and border view
    object_getInstanceVariable(self, "_editorAreaAutoLayoutView", (void**)&layoutView);
    return layoutView;
}

- (DVTBorderedView *)_xvim_debuggerBarBorderedView
{
    DVTBorderedView *border;

    // The view contains editors and border view
    object_getInstanceVariable(self, "_debuggerBarBorderedView", (void**)&border);
    return border;
}

- (void)xvim_viewDidInstall
{
    [self xvim_viewDidInstall];

    XVimWindow *xvim = [[XVimWindow alloc] initWithIDEEditorArea:self];
    NSView *layoutView = [self _xvim_editorAreaAutoLayoutView];
    XVimCommandLine *cmd = xvim.commandLine;

    [layoutView addSubview:cmd];

    // This notification is to resize command line view according to the editor area size.
    [[NSNotificationCenter defaultCenter] addObserver:cmd
                                             selector:@selector(didFrameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:layoutView];
    if (layoutView.subviews.count > 0) {
        DVTBorderedView *border = [self _xvim_debuggerBarBorderedView];

        // We need to know if border view is hidden or not to place editors and command line correctly.
        [border addObserver:cmd forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    }

    objc_setAssociatedObject(self, KEY_WINDOW, xvim, OBJC_ASSOCIATION_RETAIN);
    [xvim release];
}

- (void)xvim_primitiveInvalidate
{
    XVimCommandLine *cmd = self.xvim_window.commandLine;
    DVTBorderedView *border = [self _xvim_debuggerBarBorderedView];

    [border removeObserver:cmd forKeyPath:@"hidden"];
    [[NSNotificationCenter defaultCenter] removeObserver:cmd];

    [self xvim_primitiveInvalidate];
}

@end
