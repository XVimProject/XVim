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
- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view;
- (void)didFrameChanged:(NSNotification*)notification;
- (void)setFocusOnCommandWithFirstLetter:(NSString*)first;

- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt;

@end
