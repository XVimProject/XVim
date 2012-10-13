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
#import "XVimStatusLine.h"

@implementation IDEEditorHook
+(void)hook{
    Class c = NSClassFromString(@"IDEEditor");
    
    [Hooker hookMethod:@selector(didSetupEditor) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(didSetupEditor) ) keepingOriginalWith:@selector(didSetupEditor_)];
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
			status = [[[XVimStatusLine alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease];
			[container addSubview:status];
			[status associateWith:container];
        
			// Layout
			[[NSNotificationCenter defaultCenter] addObserver:status selector:@selector(didContainerFrameChanged:) name:NSViewFrameDidChangeNotification object:container];
			[status layoutStatus:container];
			[container performSelector:@selector(invalidateLayout)];
			
			// To notify contents of editor is changed
			[editor addObserver:status forKeyPath:@"document" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
		}
    }
    //---- TO HERE ----
}
@end
