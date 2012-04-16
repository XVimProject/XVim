//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XVimCommandField.h"

@class XVimWindow;

@interface XVimCommandLine : NSView
@property NSInteger tag;

- (id)initWithWindow:(XVimWindow*)window;

- (void)setStatusString:(NSString*)string;
- (void)setArgumentString:(NSString*)string;
- (void)setStaticString:(NSString*)string;
- (void)errorMessage:(NSString*)string;

- (XVimCommandField*)commandField;

- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view;
- (void)didFrameChanged:(NSNotification*)notification;

@end
