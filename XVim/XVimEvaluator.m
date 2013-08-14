//
//  XVimEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.  
//  Copyright 2012 JugglerShu.Net. All rights reserved.  
//

#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "XVimKeyStroke.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "XVimKeymapProvider.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVim.h"
#import "NSTextView+VimOperation.h"

static XVimEvaluator* _invalidEvaluator = nil;
static XVimEvaluator* _noOperationEvaluator = nil;

@implementation XVimEvaluator

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

+ (XVimEvaluator*)noOperationEvaluator{
   	if(_noOperationEvaluator){
        return _noOperationEvaluator;
    }
    
	@synchronized([XVimEvaluator class]){
		if(!_noOperationEvaluator) {
			_noOperationEvaluator = [[XVimEvaluator alloc] init];
		}
	}
    return _noOperationEvaluator;
}

- (id)init {
    self = [super init];
	return self;
}

- (id)initWithWindow:(XVimWindow*)window{
    NSAssert( nil != window, @"window must not be nil");
    if(self = [super init]){
        self.window = window;
        self.parent = nil;
        self.argumentString = [[[NSMutableString alloc] init] autorelease];
        self.numericArg = 1;
        self.numericMode = NO;
        self.yankRegister = nil;
        self.onChildCompleteHandler = @selector(onChildComplete:);
    }
    return self;
}

- (void)dealloc{
    self.window = nil;
    self.parent = nil;
    self.argumentString = nil;
    self.yankRegister = nil;
    [super dealloc];
}

- (NSTextView*)sourceView{
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
    self.sourceView.yankDelegate = self;
}

- (void)didEndHandler{
    self.sourceView.yankDelegate = nil;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_NORMAL];
}

- (XVimEvaluator*)defaultNextEvaluator{
    return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event{
	if( self.sourceView.selectionMode == XVIM_VISUAL_NONE){
        return [[[XVimNormalEvaluator alloc] init] autorelease];
    }else{
        //return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_CHARACTER withRange:NSMakeRange(0,0)] autorelease];
        return [[[XVimNormalEvaluator alloc] init] autorelease];
    }
}

/*
- (NSRange)restrictSelectedRange:(NSRange)range{
	if (range.length == 0 && ![[self sourceView] isValidCursorPosition:range.location]) {
		--range.location;
	}
	return range;
}
 */

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

- (XVIM_MODE)mode{
    return XVIM_MODE_NORMAL;
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other {
	return other == self;
}

- (XVimEvaluator*)D_d{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    return nil;
}

- (XVimEvaluator*)ESC{
    return [XVimEvaluator invalidEvaluator];
}

// Normally argumentString, but can be overridden
- (NSString*)argumentDisplayString {
    if( nil == self.parent ){
        return _argumentString;
    }else{
        return [[self.parent argumentDisplayString] stringByAppendingString:_argumentString];
    }
}

// Returns the context yank register if any
- (NSString*)yankRegister {
    // Never use self.yankRegister here. It causes INFINITE LOOP
    if( nil != _yankRegister ){
        return [[_yankRegister retain] autorelease];
    }
    if( nil == self.parent ){
        return _yankRegister;
    }else{
        return [self.parent yankRegister];
    }
}

- (void)resetNumericArg{
    _numericArg = 1;
    if( self.parent != nil ){
        [self.parent resetNumericArg];
    }
}

// Returns the context numeric arguments multiplied together
- (NSUInteger)numericArg {
    // FIXME: This may lead integer overflow.
    // Just cut it to INT_MAX is fine for here I think.
    if( nil == self.parent ){
        return _numericArg;
    }else{
        return [self.parent numericArg] * _numericArg;
    }
}

- (BOOL)numericMode{
    if( nil == self.parent ){
        return _numericMode;
    }else{
        return [self.parent numericMode];
    }
}

- (void)textYanked:(NSString*)yankedText withType:(TEXT_TYPE)type inView:(id)view{
    TRACE_LOG(@"yanked text: %@", yankedText);
    [[[XVim instance] registerManager] yank:yankedText withType:type onRegister:self.yankRegister];
    return;
}

- (void)textDeleted:(NSString*)deletedText withType:(TEXT_TYPE)type inView:(id)view{
    TRACE_LOG(@"deleted text: %@", deletedText);
    [[[XVim instance] registerManager] delete:deletedText withType:type onRegister:self.yankRegister];
    return;
}
@end


