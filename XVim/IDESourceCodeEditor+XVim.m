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
#import "NSobject+ExtraData.h"

@implementation IDESourceCodeEditor(XVim)
+ (void)xvim_initialize{
    [self xvim_swizzleInstanceMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) with:@selector(xvim_textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
    [self xvim_swizzleInstanceMethod:@selector(initWithNibName:bundle:document:) with:@selector(xvim_initWithNibName:bundle:document:)];
}

- (NSArray*) xvim_textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    return newSelectedCharRanges;
}

- (id)xvim_initWithNibName:(NSString*)name bundle:(NSBundle*)bundle document:(IDEEditorDocument*)doc{
    id obj = [self xvim_initWithNibName:name bundle:bundle document:doc];
    NSView* container = [[obj view] contentView];
    
    // Insert status line
    if( nil != container ){
        // TODO: Observe DVTFontAndColorSourceTextSettingsChangedNotification to change color of status bar
        DVTSourceTextScrollView* scrollView = [self mainScrollView];
        [scrollView setTranslatesAutoresizingMaskIntoConstraints:NO]; // To use autolayout we need set this NO
        
        // Add status view
        XVimStatusLine* status = [[XVimStatusLine alloc] initWithString:doc.filePath.pathString];
        [status setTranslatesAutoresizingMaskIntoConstraints:NO];
        [container addSubview:status];
        
        // Bind its visibility to 'laststatus'
        XVimLaststatusTransformer* transformer = [[XVimLaststatusTransformer alloc] init];
        [status bind:@"hidden" toObject:[[XVim instance] options] withKeyPath:@"laststatus" options:@{NSValueTransformerBindingOption:transformer}];
        
        
        // View autolayout constraints (for the source view and status bar)
        
        // Same width with the parent
        [container addConstraint:[NSLayoutConstraint constraintWithItem:scrollView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:container
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
        
        // ScrollView's left position is 0
        [container addConstraint:[NSLayoutConstraint constraintWithItem:scrollView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:0.0]];
        // Position scrollView above the status bar
        [container addConstraint:[NSLayoutConstraint constraintWithItem:scrollView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:status
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
        // ScrollView fills to top of the container view
        [container addConstraint:[NSLayoutConstraint constraintWithItem:scrollView
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
    
    return obj;
}
@end