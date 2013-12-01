//
//  IDEEditor.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>
#import "XVim.h"
#import "XVimWindow.h"
#import "XVimStatusLine.h"
#import "IDESourceEditor.h"

#import "IDEKit.h"
#import "IDEEditor+XVim.h"
#import "NSObject+XVimAdditions.h"
#import "DVTSourceTextView+XVim.h"
#import "Logger.h"

static char const * const DID_REGISTER_OBSERVER_KEY = "net.JugglerShu.IDEEditorHook._didRegisterObserver";


@interface IDESourceCodeVersionsLogSubmode ()
- (void)xvim_setPrimaryEditor:(IDEEditor *)primaryEditor;
@end

@interface IDESourceCodeVersionsBlameSubmode ()
- (void)xvim_setPrimaryEditor:(IDEEditor *)primaryEditor;
@end

@interface IDESourceCodeVersionsTwoUpSubmode ()
- (void)xvim_setPrimaryEditor:(IDEEditor *)primaryEditor;
- (void)xvim_setSecondaryEditor:(IDEEditor *)secondaryEditor;
@end

static void xvim_setPrimaryEditor(id self, SEL _cmd, IDEEditor *editor)
{
    [self xvim_setPrimaryEditor:editor];
    [editor xvim_tryToSetupXVimView];
}

static void xvim_setSecondaryEditor(id self, SEL _cmd, IDEEditor *editor)
{
    [self xvim_setSecondaryEditor:editor];
    [editor xvim_tryToSetupXVimView];
}

@implementation IDEEditor (XVim)

+ (void)xvim_initialize
{
    if (self == [IDEEditor class]) {
        [NSClassFromString(@"IDESourceCodeVersionsLogSubmode")
         xvim_swizzleInstanceMethod:@selector(setPrimaryEditor:)
         with:@selector(xvim_setPrimaryEditor:)
         imp:(IMP)xvim_setPrimaryEditor];

        [NSClassFromString(@"IDESourceCodeVersionsBlameSubmode")
         xvim_swizzleInstanceMethod:@selector(setPrimaryEditor:)
         with:@selector(xvim_setPrimaryEditor:)
         imp:(IMP)xvim_setPrimaryEditor];

        [NSClassFromString(@"IDESourceCodeVersionsTwoUpSubmode")
         xvim_swizzleInstanceMethod:@selector(setPrimaryEditor:)
         with:@selector(xvim_setPrimaryEditor:)
         imp:(IMP)xvim_setPrimaryEditor];

        [NSClassFromString(@"IDESourceCodeVersionsTwoUpSubmode")
         xvim_swizzleInstanceMethod:@selector(setSecondaryEditor:)
         with:@selector(xvim_setSecondaryEditor:)
         imp:(IMP)xvim_setSecondaryEditor];

        [self xvim_swizzleInstanceMethod:@selector(didSetupEditor)
                                    with:@selector(xvim_didSetupEditor)];
        [self xvim_swizzleInstanceMethod:@selector(primitiveInvalidate)
                                    with:@selector(xvim_primitiveInvalidate)];
    }
}

- (void)xvim_tryToSetupXVimView
{
    if ([self isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        DVTSourceTextView *tv = (DVTSourceTextView *)[(id)self textView];
        XVimWindow *window = tv.xvimWindow;

        if (window && self.document.fileURL.isFileURL) {
            DVTTextStorage *ts = [tv textStorage];
            if (ts && !ts.xvim_buffer) {
                [XVimBuffer makeBufferForDocument:self.document textStorage:ts];
            }
            if (tv && !tv.xvim_view) {
                [tv xvim_makeXVimViewInWindow:window];
            }
        }
    }
}

- (void)xvim_didSetupEditor
{
    [self xvim_didSetupEditor];

    if ([self isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        [self xvim_tryToSetupXVimView];
    } else if ([self isKindOfClass:[IDEComparisonEditor class]]) {
        [[[(IDEComparisonEditor *)self submode] primaryEditor] xvim_tryToSetupXVimView];
        [[[(IDEComparisonEditor *)self submode] secondaryEditor] xvim_tryToSetupXVimView];
    }

    // If you do not like status line comment out folloing.
    // ---- FROM HERE ----
    NSView *container = nil;

    if ([self isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        container = [(IDESourceCodeComparisonEditor*)self layoutView];
    } else if ([self isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        container = [(IDESourceCodeEditor*)self containerView];
    } else {
        return;
    }

    if (container != nil) {
        XVimStatusLine *status = [XVimStatusLine associateOf:container];
        if (status == nil) {
            // Insert status line
            [container setPostsFrameChangedNotifications:YES];
            status = [[[XVimStatusLine alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease];
            [container addSubview:status];
            [status associateWith:container];

            // Layout
            [[NSNotificationCenter defaultCenter] addObserver:status selector:@selector(didContainerFrameChanged:) name:NSViewFrameDidChangeNotification object:container];
            [status layoutStatus:container];
            [container performSelector:@selector(invalidateLayout)];

            // For % register and to notify contents of editor is changed
            [self addObserver:[XVim instance] forKeyPath:@"document" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
            objc_setAssociatedObject(self, DID_REGISTER_OBSERVER_KEY, @YES, OBJC_ASSOCIATION_ASSIGN);
        }
    }
    //---- TO HERE ----
}

- (void)xvim_primitiveInvalidate
{
    if (objc_getAssociatedObject(self, DID_REGISTER_OBSERVER_KEY)) {
        [self removeObserver:[XVim instance] forKeyPath:@"document"];
    }
    [self xvim_primitiveInvalidate];
}

@end
