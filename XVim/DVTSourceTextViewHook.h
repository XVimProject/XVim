//
//  DVTSourceTextView.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DVTKit.h"

@class DVTSourceTextView;
@class XVimStatusLine;

@interface DVTSourceTextViewHook : NSObject
+ (void)hook;
@end

@interface DVTSourceTextView(Hook)
- (void)setSelectedRange_:(NSRange)charRange;
- (void)setSelectedRange_:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag;
- (void)keyDown_:(NSEvent *)theEvent;
- (void)mouseDown_:(NSEvent *)theEvent;
- (void)mouseUp_:(NSEvent *)theEvent;
- (void)mouseDragged_:(NSEvent *)theEvent;
- (void)drawRect_:(NSRect)dirtyRect;
- (BOOL) performKeyEquivalent_:(NSEvent *)theEvent;
- (BOOL)shouldDrawInsertionPoint_;
- (void)_drawInsertionPointInRect_:(NSRect)aRect color:(NSColor*)aColor;
- (void)drawInsertionPointInRect_:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag;
- (BOOL)becomeFirstResponder_;
- (void)viewDidMoveToSuperview_;
@end
