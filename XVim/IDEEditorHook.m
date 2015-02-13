//
//  IDEEditor.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEEditorHook.h"
#import "IDEKit.h"
#import "IDESourceEditor.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVim.h"
#import "XVimStatusLine.h"
#import <objc/runtime.h>

#define DID_REGISTER_OBSERVER_KEY   "net.JugglerShu.IDEEditorHook._didRegisterObserver"

@implementation IDEEditorHook
+(void)hook{
    Class c = NSClassFromString(@"IDEEditor");
    
    [Hooker hookMethod:@selector(didSetupEditor) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(didSetupEditor) ) keepingOriginalWith:@selector(didSetupEditor_)];
    [Hooker hookMethod:@selector(primitiveInvalidate) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(primitiveInvalidate)) keepingOriginalWith:@selector(primitiveInvalidate_)];
}

- (void)didSetupEditor{
    
    IDEEditor* editor = (IDEEditor*)self;
    [editor didSetupEditor_];
    
    // If you do not like status line comment out folloing.
    // ---- FROM HERE ----
    NSView* container = nil;
    if( [NSStringFromClass([editor class]) isEqualToString:@"IDESourceCodeComparisonEditor"] ){
        container = [(IDESourceCodeComparisonEditor*)editor layoutView];
    }
    else if( [NSStringFromClass([editor class]) isEqualToString:@"IDESourceCodeEditor"] ){
        container = [(IDESourceCodeEditor*)editor containerView];
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
            [editor addObserver:[XVim instance] forKeyPath:@"document" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
            objc_setAssociatedObject(editor, DID_REGISTER_OBSERVER_KEY, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
		}
    }
    //---- TO HERE ----
}

- (void)primitiveInvalidate {
    IDEEditor *editor = (IDEEditor *)self;
    NSNumber *didRegisterObserver = objc_getAssociatedObject(editor, DID_REGISTER_OBSERVER_KEY);
    if ([didRegisterObserver boolValue]) {
        [editor removeObserver:[XVim instance] forKeyPath:@"document"];
    }
    
    [editor primitiveInvalidate_];
}

@end
