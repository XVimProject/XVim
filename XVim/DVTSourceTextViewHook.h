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
+ (void)unhook;
@end

@interface DVTSourceTextView(Hook)
- (id)initWithCoder_:(NSCoder*)rect;
// When initialize Xcode just calls initWithCoder and do not call these 2 initializer
// - (id)initWithFrame_:(NSRect)rect;
// - (id)initWithFrame_:(NSRect)rect textContainer:(NSTextContainer *)container;
- (void)dealloc_;
- (void)setSelectedRanges_:(NSArray*)array affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag;
- (void)keyDown_:(NSEvent *)theEvent;
- (void)mouseDown_:(NSEvent *)theEvent;
- (void)mouseUp_:(NSEvent *)theEvent;
- (void)mouseDragged_:(NSEvent *)theEvent;
- (void)drawRect_:(NSRect)dirtyRect;
- (BOOL) performKeyEquivalent_:(NSEvent *)theEvent;
- (BOOL)shouldDrawInsertionPoint_;
- (void)_drawInsertionPointInRect_:(NSRect)aRect color:(NSColor*)aColor;
- (BOOL)becomeFirstResponder_;
- (void)didChangeText_;
- (void)viewDidMoveToSuperview_;
@end