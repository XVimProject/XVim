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
#import "XVim.h"

static XVimEvaluator* _invalidEvaluator = nil;

@interface XVimEvaluator() {
}
@end

@implementation XVimEvaluator
@synthesize window = _window;
@synthesize parent = _parent;
@synthesize numericArg = _numericArg;
@synthesize argumentString = _argumentString;
@synthesize onChildCompleteHandler = _onChildCompleteHandler;


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
    self.sourceView.delegate = self;
}

- (void)didEndHandler{
    self.sourceView.delegate = nil;
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
	if( [self sourceView].selectionMode == MODE_VISUAL_NONE){
        return [[[XVimNormalEvaluator alloc] init] autorelease];
    }else{
        return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:MODE_CHARACTER withRange:NSMakeRange(0,0)] autorelease];
    }
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
        return [[self.parent argumentString] stringByAppendingString:_argumentString];
    }
}

// Returns the context yank register if any
- (XVimRegister*)yankRegister {
    if( nil != _yankRegister ){
        return [[_yankRegister retain] autorelease];
    }
    if( nil == self.parent ){
        if( _yankRegister == nil ){
            // Bottom most evaluator of a evaluator stack returns
            // "DQUOTE" register as a default yank register
            return [[[[XVim instance] findRegister:@"DQUOTE"] retain] autorelease];
        }
        return _yankRegister;
    }else{
        return [self.parent yankRegister];
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

- (void)textYanked:(NSString*)yankedText withType:(TEXT_TYPE)type inView:(id)view{
    TRACE_LOG(@"yanked text: %@", yankedText);
    
    // TODO:
    // This is temprary impl.
    // Should avoid using XVim instance.
    XVim* xvim = [XVim instance];
    
    // Unnamed register
    [[xvim findRegister:@"DQUOTE"] clear];
    [[xvim findRegister:@"DQUOTE"] appendText:yankedText];
    [xvim findRegister:@"DQUOTE"].type = type;
    
    
    // Don't do anything if we are recording into the register (that isn't the repeat register)
    if (xvim.recordingRegister == self.yankRegister){
        return;
    }

    // If we are yanking into a specific register then we do not cycle through
    // the numbered registers.
    if (_yankRegister != nil){
        [_yankRegister clear];
        [_yankRegister appendText:yankedText];
        _yankRegister.type = type;
    }else{
        // There are 10 numbered registers
        // Cycle number registers
        // TODO: better not copying the text to cycle
        //       we can use some pointer to point the head of ring buffer for numbered registers
        for (NSUInteger i = xvim.numberedRegisters.count - 2; ; --i){
            XVimRegister *prev = [xvim.numberedRegisters objectAtIndex:i];
            XVimRegister *next = [xvim.numberedRegisters objectAtIndex:i+1];
            [next clear];
            [next appendText:prev.string];
            next.type  = prev.type;
            if( i == 0 ){
                break;
            }
        }
        
        XVimRegister *reg = [xvim.numberedRegisters objectAtIndex:0];
        [reg clear];
        [reg appendText:yankedText];
        reg.type = type;
    }
    
    return;
}

- (void)textDeleted:(NSString*)deletedText withType:(TEXT_TYPE)type inView:(id)view{
    TRACE_LOG(@"deleted text: %@", deletedText);
    
    // TODO:
    // This is temprary impl.
    // Should avoid using XVim instance.
    XVim* xvim = [XVim instance];
    
    // Unnamed register
    [[xvim findRegister:@"DQUOTE"] clear];
    [[xvim findRegister:@"DQUOTE"] appendText:deletedText];
    [xvim findRegister:@"DQUOTE"].type = type;
    
    
    // Don't do anything if we are recording into the register (that isn't the repeat register)
    if (xvim.recordingRegister == self.yankRegister){
        return;
    }

    // If we are yanking into a specific register then we do not cycle through
    // the numbered registers.
    if (_yankRegister != nil){
        [_yankRegister clear];
        [_yankRegister appendText:deletedText];
        _yankRegister.type = type;
    }else{
        // There are 10 numbered registers
        // Cycle number registers
        // TODO: better not copying the text to cycle
        //       we can use some pointer to point the head of ring buffer for numbered registers
        for (NSUInteger i = xvim.numberedRegisters.count - 2; ; --i){
            XVimRegister *prev = [xvim.numberedRegisters objectAtIndex:i];
            XVimRegister *next = [xvim.numberedRegisters objectAtIndex:i+1];
            [next clear];
            [next appendText:prev.string];
            next.type  = prev.type;
            if( i == 0 ){
                break;
            }
        }
        
        XVimRegister *reg = [xvim.numberedRegisters objectAtIndex:0];
        [reg clear];
        [reg appendText:deletedText];
        reg.type = type;
    }
    
    XVimRegister *defaultReg = [xvim findRegister:@"DQUOTE"];
    [defaultReg clear];
    [defaultReg appendText:deletedText];
    return;
}

/*
- (XVimEvaluatorContext*)context{
	return [[_context retain] autorelease];
}
 

// Equivalent to [[self context] copy]
- (XVimEvaluatorContext*)contextCopy {
	return [[self context] copy];
}

// Clears the context and returns self, useful for escaping from operators
- (XVimEvaluator*)withNewContext {
	self.context = [[[XVimEvaluatorContext alloc] init] autorelease];
	return self;
}

- (XVimEvaluator*)withNewContext:(XVimEvaluatorContext*)context{
	self.context = context;
	return self;
}
 */

@end


