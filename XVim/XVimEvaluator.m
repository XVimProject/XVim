//
//  XVimEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.  
//  Copyright 2012 JugglerShu.Net. All rights reserved.  
//

#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimKeyStroke.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "XVimKeymapProvider.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"

@implementation XVimEvaluator

- (void)becameHandlerInWindow:(XVimWindow*)window {
}

- (XVIM_MODE)mode {
    return MODE_NORMAL;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    // This is default implementation of evaluator.
    // Only keyDown events are supposed to be passed here.	
    // Invokes each key event handler
    // <C-k> invokes "C_k:" selector
	
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler)
	{
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler withObject:window];
	}
    else{
        TRACE_LOG(@"SELECTOR %@ not found", NSStringFromSelector(handler));
        return [self defaultNextEvaluatorInWindow:window];
    }
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_GLOBAL_MAP];
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window{
    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (xregister.isReadOnly){
        return REGISTER_IGNORE;
    }
    return REGISTER_APPEND;
}

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window {
    NSRange range = [[window sourceView] selectedRange];
    return range.location + range.length;
}

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event inWindow:(XVimWindow*)window
{
	NSRange range = [window selectedRange];
	return range.length == 0 ? [[XVimNormalEvaluator alloc] init] : [[XVimVisualEvaluator alloc] initWithMode:MODE_CHARACTER 
																									withRange:range];
}

- (NSRange)restrictSelectedRange:(NSRange)range inWindow:(XVimWindow*)window
{
	if (range.length == 0 && ![[window sourceView] isValidCursorPosition:range.location])
	{
		--range.location;
	}
	return range;
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return YES;
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window
{
	DVTSourceTextView *sourceView = [window sourceView];
	
	color = [color colorWithAlphaComponent:0.5];
	NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
	NSUInteger glyphIndex = [[sourceView layoutManager] glyphIndexForPoint:aPoint inTextContainer:[sourceView textContainer]];
	NSRect glyphRect = [[sourceView layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[sourceView textContainer]];
	
	[color set];
	rect.size.width =rect.size.height/2;
	if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
		rect.size.width=glyphRect.size.width;
	NSRectFillUsingOperation( rect, NSCompositeSourceOver);
}

- (XVimEvaluator*)D_d:(XVimWindow*)window{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    
    return nil;
}
@end


