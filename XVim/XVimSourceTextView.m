//
//  DVTSourceTextView.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimSourceTextView.h"
#import "XVimEvaluator.h"
#import "XVim.h"
#import "Hooker.h"
#import "Logger.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"

@implementation XVimSourceTextView

+ (void)hook
{
    Class c = NSClassFromString(@"DVTSourceTextView");
    
    // Hook setSelectedRange:
    [Hooker hookMethod:@selector(setSelectedRange:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(setSelectedRange:) ) keepingOriginalWith:@selector(setSelectedRange_:)];
    
    // Hook setSelectedRange:affinity:stillSelecting:
    [Hooker hookMethod:@selector(setSelectedRange:affinity:stillSelecting:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(setSelectedRange:affinity:stillSelecting:) ) keepingOriginalWith:@selector(setSelectedRange_:affinity:stillSelecting:)];
    
    // Hook initWithCoder:
    [Hooker hookMethod:@selector(initWithCoder:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(initWithCoder:) ) keepingOriginalWith:@selector(initWithCoder_:)];
    
    // Hook viewDidMoveToSuperview
    [Hooker hookMethod:@selector(viewDidMoveToSuperview) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(viewDidMoveToSuperview) ) keepingOriginalWith:@selector(viewDidMoveToSuperview_)];
    
    // Hook keyDown:
    [Hooker hookMethod:@selector(keyDown:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(keyDown:) ) keepingOriginalWith:@selector(keyDown_:)];   
    
    // Hook mouseDown:
    [Hooker hookMethod:@selector(mouseDown:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(mouseDown:) ) keepingOriginalWith:@selector(mouseDown_:)];
	
    // Hook mouseUp:
    [Hooker hookMethod:@selector(mouseUp:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(mouseUp:) ) keepingOriginalWith:@selector(mouseUp_:)];    
	
    // Hook drawRect:
    [Hooker hookMethod:@selector(drawRect:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(drawRect:)) keepingOriginalWith:@selector(drawRect_:)];
    
    // Hook performKeyEquivalent:
    [Hooker hookMethod:@selector(performKeyEquivalent:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(performKeyEquivalent:)) keepingOriginalWith:@selector(performKeyEquivalent_:)];
    
    // Hook shouldDrawInsertionPoint for Drawing Caret
    [Hooker hookMethod:@selector(shouldDrawInsertionPoint) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(shouldDrawInsertionPoint)) keepingOriginalWith:@selector(shouldDrawInsertionPoint_)];
    
    // Hook drawInsertionPointInRect for Drawing Caret
    [Hooker hookMethod:@selector(drawInsertionPointInRect:color:turnedOn:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(drawInsertionPointInRect:color:turnedOn:)) keepingOriginalWith:@selector(drawInsertionPointInRect_:color:turnedOn:)];
    
    // Hook _drawInsertionPointInRect for Drawing Caret       
    [Hooker hookMethod:@selector(_drawInsertionPointInRect:color:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(_drawInsertionPointInRect:color:)) keepingOriginalWith:@selector(_drawInsertionPointInRect_:color:)];
    
    // Hook doCommandBySelector:
    [Hooker hookMethod:@selector(doCommandBySelector:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(doCommandBySelector:)) keepingOriginalWith:@selector(doCommandBySelector_:)];    
}

- (void)setSelectedRange:(NSRange)charRange {
    // Call original method
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    [base setSelectedRange_:charRange];
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    [xvim setNextSearchBaseLocation: charRange.location];
    return;
}

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    NSRange newCharRange = charRange;
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    if( xvim.handlingMouseClick && xvim.mode != MODE_INSERT && ![base isValidCursorPosition:charRange.location] ){
        newCharRange.location = charRange.location - 1;
    }
    
    // Call original method
    [base setSelectedRange_:newCharRange affinity:affinity stillSelecting:flag];
    return;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    // New DVTSourceTextView is being created. (Remember that "self" is DVTSourceTextView object since this is hooked method )
    // What we do here is to create XVim object
    // which corresponds to this object
    // and set it as a (hidden) subview of this DVTSourceTextView.
    
    // Call original method
    [base initWithCoder_:aDecoder];
    
    XVim* xvim = [[XVim alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)]; // XVim is dummy NSView object. This is not worked as a view. Just because to keep this object as subview in DVTSourceTextView 
    // Bind DVTSourceTextView and XVim object by tagging    
    xvim.tag = XVIM_TAG;
    [base addSubview:xvim];
    return (id)base;
}

- (void)viewDidMoveToSuperview{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
	XVim* xvim = [base viewWithTag:XVIM_TAG];
    if( nil != xvim ){
        TRACE_LOG(@"XVim object found");
        XVimCommandLine* cmdline = [[[XVimCommandLine alloc] initWithXVim:xvim] autorelease];
        xvim.cmdLine = cmdline; 
        xvim.sourceView = base;
        
        // Try to find parent scroll view
        NSScrollView* scrollView = [base enclosingScrollView]; // DVTSourceTextScrollView
        if( nil != scrollView ){
            
            [[scrollView contentView] setCopiesOnScroll:NO];
            // Add status bar in DVTSourceTextScrollView
            [scrollView addSubview:cmdline positioned:NSWindowAbove relativeTo:nil];
            // Observe DVTSourceScrollTextView notification
            [scrollView setPostsFrameChangedNotifications:YES];
            [[NSNotificationCenter defaultCenter] addObserver:cmdline selector:@selector(didFrameChanged:) name:NSViewFrameDidChangeNotification  object:scrollView];
        }else{
            ERROR_LOG(@"DVTSourceTExtScrollView not found.");
        }
    }else{
        ERROR_LOG(@"XVim object not found.");
    }
}

-  (void)keyDown:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    if( nil == xvim ){
        [base keyDown_:theEvent];
        return;
    }
    
    // On some configuration when the " is opened, the string is still empty because the user
    // needs to type the space button or any other character before the quote is made persistent
    NSString* ignMod =  [theEvent charactersIgnoringModifiers];
    if (ignMod == nil || [ignMod length] == 0) {
        [base keyDown_:theEvent];
        return;
    }
    
    unichar charcode = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    [Logger logWithLevel:LogDebug format:@"Obj:%p keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self,[theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode];
    
    if( [xvim handleKeyEvent:theEvent] ){
        return;
    }
    // Call Original keyDown:
    [base keyDown_:theEvent];
    return;
}

-  (void)mouseDown:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    TRACE_LOG(@"got a mouseDown:");
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    if( nil == xvim ){
        [base mouseDown_:theEvent];
        return;
    }
    
    // Call Original mouseDown:
    xvim.handlingMouseClick = YES;
    [base mouseDown_:theEvent]; // this loops until it gets a mouse up
    xvim.handlingMouseClick = NO;
    return;
}

-  (void)mouseUp:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    TRACE_LOG(@"got a mouseUp:");
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    if( nil == xvim ){
        [base mouseUp_:theEvent];
        return;
    }
	
    // Call Original mouseDown:
    xvim.handlingMouseClick = NO;
    [base mouseUp_:theEvent];
    return;
}

- (void)drawRect:(NSRect)dirtyRect{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    [base drawRect_:dirtyRect];
    
    if (MODE_VISUAL == xvim.mode){
        NSUInteger glyphIndex = xvim.currentEvaluator.insertionPoint;
        NSRect glyphRect = [[base layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:[base textContainer]];
        
        [[[base insertionPointColor] colorWithAlphaComponent:0.5] set];
        NSRectFillUsingOperation(glyphRect, NSCompositeSourceOver);
    }
}

- (BOOL) performKeyEquivalent:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    METHOD_TRACE_LOG();
    unichar charcode = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    TRACE_LOG(@"keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ ASCII:%d", [theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
    if( [[base window] firstResponder] != base){
        return NO;
    }
    
    return [base performKeyEquivalent_:theEvent];
}

- (BOOL)shouldDrawInsertionPoint{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    return (MODE_VISUAL != xvim.mode);
}

// Drawing Caret
- (void)_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    if(MODE_INSERT == xvim.mode){
        [base _drawInsertionPointInRect_:aRect color:aColor];
    }else{
        [base drawInsertionPointInRect:aRect color:aColor turnedOn:YES];
    }
}

// Drawing Caret
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    XVim* xvim = [base viewWithTag:XVIM_TAG];
    if(MODE_INSERT == xvim.mode){
        [base drawInsertionPointInRect_:rect color:color turnedOn:flag];
    }
    else{
        if(flag){
            color = [color colorWithAlphaComponent:0.5];
            NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
            NSUInteger glyphIndex = [[base layoutManager] glyphIndexForPoint:aPoint inTextContainer:[base textContainer]];
            NSRect glyphRect = [[base layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[base textContainer]];
            
            [color set];
            rect.size.width =rect.size.height/2;
            if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
                rect.size.width=glyphRect.size.width;
            NSRectFillUsingOperation( rect, NSCompositeSourceOver);
        } else {
            [base setNeedsDisplayInRect:[base visibleRect] avoidAdditionalLayout:NO];
        }
    }
}

- (void)doCommandBySelector:(SEL)aSelector{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
	
    TRACE_LOG(@"SELECTOR : ", NSStringFromSelector(aSelector));
    [base doCommandBySelector_:aSelector];
}

@end
