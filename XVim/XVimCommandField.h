//
//  XVimCommandField.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/29/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSInsetTextView.h"

@class XVimKeyStroke;
@class XVimWindow;
@class XVimCommandField;

@interface XVimCommandField : NSInsetTextView
- (void)setDelegate:(XVimWindow*)delegate;
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window;
@end
