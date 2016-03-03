//
//  XVimSourceCodeEditor.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDESourceCodeEditor+XVim.h"
#import "IDEKit.h"
#import "DVTFoundation.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimStatusLine.h"
#import "XVim.h"
#import "NSObject+XVimAdditions.h"
#import "NSObject+ExtraData.h"
#import <objc/runtime.h>

@implementation IDESourceCodeEditor(XVim)
+ (void)xvim_initialize{
    [self xvim_swizzleInstanceMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) with:@selector(xvim_textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
    [self xvim_swizzleInstanceMethod:@selector(didSetupEditor) with:@selector(xvim_didSetupEditor)];
}

- (NSArray*) xvim_textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    return newSelectedCharRanges;
}

- (void)xvim_didSetupEditor{
    [self xvim_didSetupEditor];
    NSScrollView* scrollView = [self mainScrollView];
    [self xvim_install_statusline:[scrollView superview] sibling:scrollView withDocument:self.document];
}

// Installs statusline as a child of container and sibling of slibling
- (void)xvim_install_statusline:(NSView*)container sibling:(NSView*)sibling withDocument:(IDEEditorDocument*)doc{
    
    if( nil != container && nil != sibling){

        // Add status view
        XVimStatusLine* statusLine = [[XVimStatusLine alloc] initWithString:doc.filePath.pathString];
        [statusLine sizeToFit];
        [statusLine setFrame:NSMakeRect(0.0f, 0.0f, CGRectGetWidth(sibling.bounds), CGRectGetHeight(statusLine.bounds))];
        [statusLine setAutoresizingMask:NSViewMaxYMargin | NSViewWidthSizable | NSViewMaxXMargin];
        [container addSubview:statusLine];
        
        // Bind its visibility to 'laststatus'
        XVimLaststatusTransformer* transformer = [[XVimLaststatusTransformer alloc] init];
        [statusLine bind:@"hidden" toObject:[[XVim instance] options] withKeyPath:@"laststatus" options:@{NSValueTransformerBindingOption:transformer}];
    }
}

@end
