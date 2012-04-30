//
//  XVimEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.  
//  Copyright 2012 JugglerShu.Net. All rights reserved.  
//

#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimKeyStroke.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "XVimKeymapProvider.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"

@interface XVimEvaluator() {
	XVimEvaluatorContext *_context;
}
@end

@implementation XVimEvaluator

- (id)init
{
	[NSException raise:@"Invalid init" format:@"Must call initWithContext"];
	return nil;
}

- (id)initWithContext:(XVimEvaluatorContext*)context
{
	if (self = [super init])
	{
		_context = context;
	}
	return self;
}

- (void)becameHandlerInWindow:(XVimWindow*)window 
{
}

- (void)willEndHandlerInWindow:(XVimWindow*)window
{
}

- (void)didEndHandlerInWindow:(XVimWindow*)window
{
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
	NSRange range = [[window sourceView] selectedRange];
	return range.length == 0 ? [[XVimNormalEvaluator alloc] init] : [[XVimVisualEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
																											mode:MODE_CHARACTER 
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

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio
{
	XVimSourceView *sourceView = [window sourceView];
	
	color = [color colorWithAlphaComponent:0.5];
	NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
	NSUInteger glyphIndex = [sourceView glyphIndexForPoint:aPoint];
	NSRect glyphRect = [sourceView boundingRectForGlyphIndex:glyphIndex];
	
	[color set];
	rect.size.width =rect.size.height/2;
	if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
		rect.size.width=glyphRect.size.width;
	
	rect.origin.y += (1 - heightRatio) * rect.size.height;
	rect.size.height *= heightRatio;
	
	NSRectFillUsingOperation( rect, NSCompositeSourceOver);
}

- (NSString*)modeString
{
	return @"";
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other
{
	return other == self;
}

- (XVimEvaluator*)D_d:(XVimWindow*)window{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    
    return nil;
}

// Normally argumentString, but can be overridden
- (NSString*)argumentDisplayString
{
	return [self argumentString];
}

// Returns the current stack of arguments (eg. "a10d...")
- (NSString*)argumentString
{
	return [[self context] argumentString];
}

// Returns the context yank register if any
- (XVimRegister*)yankRegister
{
	return [[self context] yankRegister];
}

// Returns the context numeric arguments multiplied together
- (NSUInteger)numericArg
{
	return [[self context] numericArg];
}

// Returns the context
- (XVimEvaluatorContext*)context
{
	return _context;
}

// Equivalent to [[self context] copy]
- (XVimEvaluatorContext*)contextCopy
{
	return [[self context] copy];
}

// Clears the context and returns self, useful for escaping from operators
- (XVimEvaluator*)withNewContext
{
	_context = [[XVimEvaluatorContext alloc] init];
	return self;
}

- (XVimEvaluator*)withNewContext:(XVimEvaluatorContext*)context
{
	_context = context;
	return self;
}

@end


