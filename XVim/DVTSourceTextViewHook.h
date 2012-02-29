//
//  DVTSourceTextViewHook.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/25/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVTSourceTextViewHook : NSTextView

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;

// Support Functions
// They are class methods since ther are called from Hooked methods.
// Hooked methods are called with a object which is not this class:DVTSourceTextViewHook.
+ (void)setSelectionRangeNone:(NSTextView*)view;


// DVTSourceTextView hooks
- (void)setSelectedRange:(NSRange)charRange;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)viewDidMoveToSuperview;
- (void)insertText:(NSString *)str;
- (void)doCommandBySelector:(SEL)aSelector;
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)aColor turnedOn:(BOOL)flag;
- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor*)aColor;
- (void)reflectScrolledClipView:(NSClipView *)aClipView;

// DVTSourceScrollTextView hooks
+ (void)didAddSubview:(NSView *)subview;
@end
