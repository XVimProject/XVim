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

static XVimEvaluator* _invalidEvaluator = nil;

@interface XVimEvaluator() {
}
@end

@implementation XVimEvaluator
@synthesize context = _context;
@synthesize window = _window;

- (id)init {
	return nil;
}

+ (XVimEvaluator*)invalidEvaluator{
   	if(_invalidEvaluator){
        return _invalidEvaluator;
    }
    
	@synchronized([XVimEvaluator class]){
		if(!_invalidEvaluator) {
			_invalidEvaluator = [[XVimEvaluator alloc] init];
		}
	}
    return _invalidEvaluator;
}

- (id)initWithContext:(XVimEvaluatorContext*)context withWindow:(XVimWindow*)window{
    NSAssert( nil != window, @"window must not be nil");
    if(self = [super init]){
        self.context = context;
        self.window = window;
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
    self.context = nil;
    self.window = nil;
}

- (XVimSourceView*)sourceView{
    return self.window.sourceView;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    // This is default implementation of evaluator.
    // Only keyDown events are supposed to be passed here.	
    // Invokes each key event handler
    // <C-k> invokes "C_k:" selector
	
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler) {
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler];
	}
    else{
        TRACE_LOG(@"SELECTOR %@ not found", NSStringFromSelector(handler));
        return [self defaultNextEvaluator];
    }
    
}

- (XVimEvaluator*)onChildComplete:(XVimEvaluator*)childEvaluator{
    return nil;
}
   
- (void)becameHandler{
    
}

- (void)didEndHandler{
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_GLOBAL_MAP];
}

- (XVimEvaluator*)defaultNextEvaluator{
    return [XVimEvaluator invalidEvaluator];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (xregister.isReadOnly){
        return REGISTER_IGNORE;
    }
    return REGISTER_APPEND;
}

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event{
	return [self sourceView].selectionMode == MODE_VISUAL_NONE ? [[[XVimNormalEvaluator alloc] init] autorelease] : [[[XVimVisualEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
                                                                                                         withWindow:self.window
																											mode:MODE_CHARACTER 
																									withRange:NSMakeRange(0,0)] autorelease];
}

- (NSRange)restrictSelectedRange:(NSRange)range{
	if (range.length == 0 && ![[self sourceView] isValidCursorPosition:range.location]) {
		--range.location;
	}
	return range;
}

- (void)drawRect:(NSRect)rect{
}

- (BOOL)shouldDrawInsertionPoint{
	return YES;
}

- (float)insertionPointHeightRatio{
    return 1.0;
}

- (float)insertionPointWidthRatio{
    return 1.0;
}

- (float)insertionPointAlphaRatio{
    return 0.5;
}

- (NSString*)modeString {
	return @"";
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other {
	return other == self;
}

- (XVimEvaluator*)D_d:(XVimWindow*)window{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    
    return nil;
}

// Normally argumentString, but can be overridden
- (NSString*)argumentDisplayString {
	return [self argumentString];
}

// Returns the current stack of arguments (eg. "a10d...")
- (NSString*)argumentString {
	return [[self context] argumentString];
}

// Returns the context yank register if any
- (XVimRegister*)yankRegister {
	return [[self context] yankRegister];
}

// Returns the context numeric arguments multiplied together
- (NSUInteger)numericArg {
	return [[self context] numericArg];
}

// Returns the context
- (XVimEvaluatorContext*)context {
	return _context;
}

// Equivalent to [[self context] copy]
- (XVimEvaluatorContext*)contextCopy {
	return [[self context] copy];
}

// Clears the context and returns self, useful for escaping from operators
- (XVimEvaluator*)withNewContext {
	_context = [[XVimEvaluatorContext alloc] init];
	return self;
}

- (XVimEvaluator*)withNewContext:(XVimEvaluatorContext*)context {
	_context = context;
	return self;
}

@end


