//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XVimCommandField.h"

@class XVim;

@interface XVimCommandLine : NSView
@property NSInteger tag;

- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view;
- (void)didFrameChanged:(NSNotification*)notification;
- (void)setFocusOnCommandWithFirstLetter:(NSString*)first;

- (id)initWithXVim:(XVim*)xvim;
- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt;

@end
