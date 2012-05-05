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

@protocol XVimCommandFieldDelegate
- (void)commandFieldLostFocus:(XVimCommandField*)commandField;
@end

@interface XVimCommandField : NSInsetTextView

- (void)setDelegate:(XVimWindow<XVimCommandFieldDelegate>*)delegate;
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window;
- (void)show;
- (void)hide;

// Hack: Prevents commandFieldLostFocus when command field disappears naturally
- (void)absorbFocusEvent;

@end
