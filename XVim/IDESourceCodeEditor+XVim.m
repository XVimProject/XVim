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
        [sibling setTranslatesAutoresizingMaskIntoConstraints:NO]; // To use autolayout we need set this NO
        
        // Add status view
        XVimStatusLine* status = [[XVimStatusLine alloc] initWithString:doc.filePath.pathString];
        [status setTranslatesAutoresizingMaskIntoConstraints:NO];
        [container addSubview:status];
        
        // Bind its visibility to 'laststatus'
        XVimLaststatusTransformer* transformer = [[XVimLaststatusTransformer alloc] init];
        [status bind:@"hidden" toObject:[[XVim instance] options] withKeyPath:@"laststatus" options:@{NSValueTransformerBindingOption:transformer}];
        
        
        // View autolayout constraints (for the source view and status bar)
        
        // Same width with the parent
        [container addConstraint:[NSLayoutConstraint constraintWithItem:sibling
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:container
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
        
        // ScrollView's left position is 0
        [container addConstraint:[NSLayoutConstraint constraintWithItem:sibling
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:0.0]];
        // Position sibling above the status bar
        [container addConstraint:[NSLayoutConstraint constraintWithItem:sibling
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:status
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
        // ScrollView fills to top of the container view
        [container addConstraint:[NSLayoutConstraint constraintWithItem:sibling
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
        // Place Status line at bottom edge
        [container addConstraint:[NSLayoutConstraint constraintWithItem:status
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
        // Status line width fills the container
        [container addConstraint:[NSLayoutConstraint constraintWithItem:status
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:1.0
                                                               constant:0.0]];
    }
}

@end
