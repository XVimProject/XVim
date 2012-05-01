//
//  IDEEditor.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEEditorHook.h"
#import "IDEEditor.h"
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
    
    NSView* container = nil;
    if( [NSStringFromClass([editor class]) isEqualToString:@"IDESourceCodeComparisonEditor"] ){
        container = [editor layoutView];
    }
    else if( [NSStringFromClass([editor class]) isEqualToString:@"IDESourceCodeEditor"] ){
        container = [editor containerView];
    }else{
        return;
    }
    
    if( container != nil && [container viewWithTag:XVIM_STATUSLINE_TAG] == nil ){
        // Insert status line
        [container setPostsFrameChangedNotifications:YES];
        XVimStatusLine* status = [[[XVimStatusLine alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease];
        [container addSubview:status];
        
        // Layout
        [[NSNotificationCenter defaultCenter] addObserver:status selector:@selector(didContainerFrameChanged:) name:NSViewFrameDidChangeNotification object:container];
        [status layoutStatus:container];
        [container performSelector:@selector(invalidateLayout)];
        
        // To notify contents of editor is changed
        [editor addObserver:status forKeyPath:@"document" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    }
}
@end
