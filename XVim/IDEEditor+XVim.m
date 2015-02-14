//
//  IDEEditor.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEEditor+XVim.h"
#import "IDEKit.h"
#import "IDESourceEditor.h"
#import "Logger.h"
#import "XVim.h"
#import "XVimStatusLine.h"
#import <objc/runtime.h>
#import "NSObject+XVimAdditions.h"

#define DID_REGISTER_OBSERVER_KEY   "net.JugglerShu.IDEEditorHook._didRegisterObserver"

@implementation IDEEditor(XVim)

+ (void)xvim_initialize{
    [self xvim_swizzleInstanceMethod:@selector(didSetupEditor) with:@selector(xvim_didSetupEditor)];
    [self xvim_swizzleInstanceMethod:@selector(primitiveInvalidate) with:@selector(xvim_primitiveInvalidate)];
}

- (void)xvim_didSetupEditor{
    
    [self xvim_didSetupEditor];
    
    // If you do not like status line comment out folloing.
    // ---- FROM HERE ----
    NSView* container = nil;
    if( [NSStringFromClass([self class]) isEqualToString:@"IDESourceCodeComparisonEditor"] ){
        container = [(IDESourceCodeComparisonEditor*)self layoutView];
    }
    else if( [NSStringFromClass([self class]) isEqualToString:@"IDESourceCodeEditor"] ){
        container = [(IDESourceCodeEditor*)self containerView];
    }else{
        return;
    }
    
    if (container != nil) {
		XVimStatusLine *status = [XVimStatusLine associateOf:container];
		if (status == nil) {
			// Insert status line
			[container setPostsFrameChangedNotifications:YES];
			status = [[XVimStatusLine alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
			[container addSubview:status];
			[status associateWith:container];
        
			// Layout
			[[NSNotificationCenter defaultCenter] addObserver:status selector:@selector(didContainerFrameChanged:) name:NSViewFrameDidChangeNotification object:container];
			[status layoutStatus:container];
			[container performSelector:@selector(invalidateLayout)];
            
            // For % register and to notify contents of editor is changed
            [self addObserver:[XVim instance] forKeyPath:@"document" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
            objc_setAssociatedObject(self, DID_REGISTER_OBSERVER_KEY, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
		}
    }
    //---- TO HERE ----
}

- (void)xvim_primitiveInvalidate {
    IDEEditor *editor = (IDEEditor *)self;
    NSNumber *didRegisterObserver = objc_getAssociatedObject(editor, DID_REGISTER_OBSERVER_KEY);
    if ([didRegisterObserver boolValue]) {
        [editor removeObserver:[XVim instance] forKeyPath:@"document"];
    }
    
    [self xvim_primitiveInvalidate];
}

@end
