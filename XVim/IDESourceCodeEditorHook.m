//
//  XVimSourceCodeEditor.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDESourceCodeEditorHook.h"
#import "IDEKit.h"
#import "XVimWindow.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVimStatusLine.h"
#import "XVimWindowManager.h"

@implementation IDESourceCodeEditorHook

+ (void) hook
{
    Class delegate = NSClassFromString(@"IDESourceCodeEditor");
	[Hooker hookMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) 
			   ofClass:delegate 
			withMethod:class_getInstanceMethod([self class], @selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)) 
   keepingOriginalWith:@selector(textView_:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
    
	[Hooker hookMethod:@selector(didSetupEditor)
			   ofClass:delegate 
			withMethod:class_getInstanceMethod([self class], @selector(didSetupEditor))
   keepingOriginalWith:@selector(didSetupEditor2_)];
}

- (NSArray*) textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    return newSelectedCharRanges;
}

- (void)didSetupEditor
{
	IDESourceCodeEditor *editor = (IDESourceCodeEditor*)self;
    [editor didSetupEditor2_];
    if (editor.isPrimaryEditor) {
        [XVimWindowManager createWithEditor:editor];
    }
}

@end