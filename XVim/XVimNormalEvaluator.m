//
//  XVimNormalEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//


#import "XVimEvaluator.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimYankEvaluator.h"
#import "XVimEqualEvaluator.h"
#import "XVimShiftEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVimRegisterEvaluator.h"
#import "XVimWindowEvaluator.h"
#import "XVimGActionEvaluator.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "NSString+VimHelper.h"
#import "XVimKeymapProvider.h"
#import "Logger.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimOptions.h"
#import "XVimRecordingEvaluator.h"

@interface XVimNormalEvaluator() {
	__weak XVimRegister *_playbackRegister;
}
@end

@implementation XVimNormalEvaluator

-(id)initWithWindow:(XVimWindow *)window{
	self = [super initWithWindow:window];
    if (self) {
    }
    return self;
}
    
- (void)becameHandler{
    [super becameHandler];
    [self.sourceView changeSelectionMode:MODE_VISUAL_NONE];
}

- (NSString*)modeString {
    return @"";
}

- (XVIM_MODE)mode{
    return MODE_NORMAL;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_NORMAL];
}

/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////

// Command which results in cursor motion should be implemented in XVimMotionEvaluator

- (XVimEvaluator*)a{
    [[self sourceView] append];
	return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)A{
    XVimSourceView* view = [self sourceView];
    [view appendAtEndOfLine];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_b{
    [[self sourceView] scrollPageBackward:[self numericArg]];
    return nil;
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c{
	//XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister] insertModeAtCompletion:TRUE];
    [self.argumentString appendString:@"c"];
    return [[[XVimDeleteEvaluator alloc] initWithWindow:self.window
								 insertModeAtCompletion:YES] autorelease];
}

// 'C' works similar to 'D' except that once it's done deleting
// it should go into insert mode
- (XVimEvaluator*)C{
    [self D];
    [[self sourceView] append];
    return [[XVimInsertEvaluator alloc] initWithWindow:self.window];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_d{
    [[self sourceView] scrollHalfPageForward:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)d{
	//XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister] insertModeAtCompletion:NO];
    [self.argumentString appendString:@"d"];
    return [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:FALSE] autorelease];
}

- (XVimEvaluator*)D{
    XVimSourceView* view = [self sourceView];
    XVimMotion* m= XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]);
    [view delete:m];
    [[XVim instance] fixRepeatCommand];
    return nil;
}

- (XVimEvaluator*)C_e{
    [[self sourceView] scrollLineForward:[self numericArg]];
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_f{
    [[self sourceView] scrollPageForward:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)C_g{
    // process
    XVimWindow* window = self.window;
    NSRange range = [[window sourceView] selectedRange];
    NSUInteger numberOfLines = [[window sourceView] numberOfLines];
    long long lineNumber = [[window sourceView] currentLineNumber];
    NSUInteger columnNumber = [[window sourceView] columnNumber:range.location];
    NSURL* documentURL = [[window sourceView] documentURL];
	if( [documentURL isFileURL] ) {
		NSString* filename = [documentURL path];
		NSString* text = [NSString stringWithFormat:@"%@   line %lld of %ld --%d%%-- col %ld",
                          filename, lineNumber, numberOfLines, (int)((float)lineNumber*100.0/(float)numberOfLines), columnNumber+1 ];
        
		[window statusMessage:text];
	}
    return nil;
}

- (XVimEvaluator*)g{
    [self.argumentString appendString:@"g"];
    self.onChildCompleteHandler = @selector(onComplete_g:);
    return [[[XVimGActionEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_g:(XVimGActionEvaluator*)childEvaluator{
    if( childEvaluator.motion != nil ){
        return [self _motionFixed:childEvaluator.motion];
    }
    return nil;
}

- (XVimEvaluator*)i{
    // Go to insert 
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)I{
    [[self sourceView] insertBeforeFirstNonBlank];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

// For 'J' (join line) bring the line up from below. all leading whitespac
// of the line joined in should be stripped and then one space should be inserted 
// between the joined lines
- (XVimEvaluator*)J{
    [[self sourceView] join:[self numericArg]];
    return nil;
}

// Should be moved to XVimMotionEvaluator

- (XVimEvaluator*)m{
    // 'm{letter}' sets a local mark.
    [self.argumentString appendString:@"m"];
	return [[[XVimMarkSetEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)o{
    XVimSourceView* view = [self sourceView];
    [view insertNewlineBelowAndInsert];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)O{
    XVimSourceView* view = [self sourceView];
    [view insertNewlineAboveAndInsert];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)C_o{
    [NSApp sendAction:@selector(goBackInHistoryByCommand:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)C_i{
    [NSApp sendAction:@selector(goForwardInHistoryByCommand:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)p{
    XVimSourceView* view = [self sourceView];
    XVimRegister* reg = [[[XVim instance] registerManager] registerByName:self.yankRegister];
    [view put:reg.string withType:reg.type afterCursor:YES count:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)P{
    XVimSourceView* view = [self sourceView];
    XVimRegister* reg = [[[XVim instance] registerManager] registerByName:self.yankRegister];
    [view put:reg.string withType:reg.type afterCursor:NO count:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)q{
    if( [XVim instance].isExecuting ){
        return nil;
    }
    [self.argumentString appendString:@"q"];
    XVimEvaluator* e = [[[XVimRegisterEvaluator alloc] initWithWindow:self.window] autorelease];
    self.onChildCompleteHandler = @selector(onComplete_q:);
    return e;
}

- (XVimEvaluator*)onComplete_q:(XVimRegisterEvaluator*)childEvaluator{
    if( [[[XVim instance] registerManager] isValidForRecording:childEvaluator.reg] ){
        self.onChildCompleteHandler = @selector(onComplete_Recording:);
        return [[XVimRecordingEvaluator alloc] initWithWindow:self.window withRegister:childEvaluator.reg];
    }
    [[XVim instance] ringBell];
    return nil;
}

- (XVimEvaluator*)onComplete_Recording:childEvaluator{
    return nil;
}

- (XVimEvaluator*)C_r{
    XVimSourceView* view = [self sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
		[view redo];
    }
    return nil;
}

- (XVimEvaluator*)r{
	[self.argumentString appendString:@"r"];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:YES] autorelease];
}

- (XVimEvaluator*)s{
    XVimSourceView *view = [self sourceView];
    NSRange r = [view selectedRange];
	
	// Set range to replace, ensuring we don't run over the end of the buffer
	NSUInteger endi = r.location + [self numericArg];
	NSUInteger maxi = [[view string] length];
	endi = MIN(endi, maxi);
	NSRange replacementRange = NSMakeRange(r.location, endi - r.location);
	
    [view setSelectedRange:replacementRange];
	
	//Xode crashes if we cut a zero length selection
	if (replacementRange.length > 0){
		[view deleteText];
	}
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO] autorelease];
}

// "S" is Synonym for "cc"
- (XVimEvaluator*)S{
    XVimDeleteEvaluator* d = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES] autorelease];
    return [d performSelector:@selector(c)];
}

- (XVimEvaluator*)u{
    XVimSourceView* view = [self sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [view undo];
    }
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_u{
    [[self sourceView] scrollHalfPageBackward:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)v{
    return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:MODE_CHARACTER] autorelease];
}

- (XVimEvaluator*)V{
    return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:MODE_LINE] autorelease];
}

- (XVimEvaluator*)C_v{
    // Block selection
    return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:MODE_BLOCK]  autorelease];
}

- (XVimEvaluator*)C_w{
    [self.argumentString appendString:@"^W"];
    return [[[XVimWindowEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)x{
    XVimSourceView* view = [self sourceView];
    XVimMotion* m= XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg]);
    [view delete:m];
    [[XVim instance] fixRepeatCommand];
    return nil;
}

// like 'x" but it goes backwards instead of forwards
- (XVimEvaluator*)X{
    XVimSourceView* view = [self sourceView];
    XVimMotion* m= XVIM_MAKE_MOTION(MOTION_BACKWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg]);
    [view delete:m];
    return nil;
}

- (XVimEvaluator*)Y{
    [self.argumentString appendString:@"Y"];
    XVimYankEvaluator* yank = [[[XVimYankEvaluator alloc] initWithWindow:self.window] autorelease];
    return [yank y];
}

- (XVimEvaluator*)y{
    [self.argumentString appendString:@"y"];
    return [[[XVimYankEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)C_y{
    [[self sourceView] scrollLineBackward:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)AT{
    if( [XVim instance].isExecuting ){
        return nil;
    }
    [self.argumentString appendString:@"@"];
    XVimEvaluator *eval = [[[XVimRecordingRegisterEvaluator alloc] initWithWindow:self.window] autorelease];
    self.onChildCompleteHandler = @selector(onComplete_AT:);
	return eval;
}

- (XVimEvaluator*)onComplete_AT:(XVimRecordingRegisterEvaluator*)childEvaluator{
    self.onChildCompleteHandler = @selector(onChildComplete:);
    XVimRegister* reg = [[[XVim instance] registerManager] registerByName:childEvaluator.reg];
    
    [XVim instance].isExecuting = YES;
    NSUInteger count = self.numericArg;
    [self resetNumericArg];
    for( NSUInteger repeat = 0 ; repeat < count; repeat++ ){
        for( XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(reg.string) ){
            [self.window handleKeyStroke:stroke onStack:nil];
        }
    }
    [XVim instance].isExecuting = NO;
    return [XVimEvaluator noOperationEvaluator];
}

- (XVimEvaluator*)DQUOTE{
    [self.argumentString appendString:@"\""];
    self.onChildCompleteHandler = @selector(onComplete_DQUOTE:);
    return  [[[XVimRegisterEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_DQUOTE:(XVimRegisterEvaluator*)childEvaluator{
    XVimRegisterManager* m = [[XVim instance] registerManager];
    if( [m isValidRegister:childEvaluator.reg] ){
        self.yankRegister = childEvaluator.reg;
        [self.argumentString appendString:childEvaluator.reg];
        self.onChildCompleteHandler = @selector(onChildComplete:);
        return self;
        
    }else{
        return [XVimEvaluator invalidEvaluator];
    }
}

- (XVimEvaluator*)EQUAL{
    [self.argumentString appendString:@"="];
    return [[[XVimEqualEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)GREATERTHAN{
    [self.argumentString appendString:@">"];
    XVimShiftEvaluator* eval =  [[[XVimShiftEvaluator alloc] initWithWindow:self.window unshift:NO] autorelease];
    return eval;
}

- (XVimEvaluator*)LESSTHAN{
    [self.argumentString appendString:@"<"];
    XVimShiftEvaluator* eval =  [[[XVimShiftEvaluator alloc] initWithWindow:self.window unshift:YES] autorelease];
    return eval;
}

- (XVimEvaluator*)HT{
    [[self sourceView] selectNextPlaceholder];
    return nil;
}

- (XVimEvaluator*)COLON{
	XVimEvaluator *eval = [[[XVimCommandLineEvaluator alloc] initWithWindow:self.window
                                                                firstLetter:@":"
                                                                    history:[[XVim instance] exCommandHistory]
                                                                 completion:^ XVimEvaluator* (NSString* command) 
                           {
                               XVimExCommand *excmd = [[XVim instance] excmd];
                               [excmd executeCommand:command inWindow:self.window];
                               return nil;
                           }
                                                                 onKeyPress:nil] autorelease];
	
	return eval;
}

- (XVimEvaluator*)executeSearch:(XVimWindow*)window firstLetter:(NSString*)firstLetter {
	XVimEvaluator *eval = [[[XVimCommandLineEvaluator alloc] initWithWindow:self.window
                                                                firstLetter:firstLetter
                                                                    history:[[XVim instance] searchHistory]
                                                                 completion:^ XVimEvaluator* (NSString *command)
						   {
							   XVimSearch *searcher = [[XVim instance] searcher];
							   XVimSourceView *sourceView = [self sourceView];
							   NSRange found = [searcher executeSearch:command 
															   display:[command substringFromIndex:1] 
																  from:[self.window insertionPoint]
															  inWindow:window];
							   //Move cursor and show the found string
							   if (found.location != NSNotFound) {
								   [sourceView setSelectedRange:NSMakeRange(found.location, 0)];
								   [sourceView scrollTo:[self.window insertionPoint]];
								   [sourceView showFindIndicatorForRange:found];
							   } else {
								   [self.window errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchDisplayString] ringBell:TRUE];
							   }
							   return nil;
						   }
                                                                 onKeyPress:^void(NSString *command)
                           {
                               XVimOptions *options = [[XVim instance] options];
                               if (options.incsearch){
                                   XVimSearch *searcher = [[XVim instance] searcher];
                                   XVimSourceView *sourceView = [self sourceView];
                                   NSRange found = [searcher executeSearch:command 
																   display:[command substringFromIndex:1]
																	  from:[self.window insertionPoint]
																  inWindow:window];
                                   //Move cursor and show the found string
                                   if (found.location != NSNotFound) {
                                       [sourceView scrollTo:found.location];
                                       [sourceView showFindIndicatorForRange:found];
                                   }
                               }
                           }] autorelease];
	return eval;
}

- (XVimEvaluator*)QUESTION{
	return [self executeSearch:self.window firstLetter:@"?"];
}

- (XVimEvaluator*)SLASH{
	return [self executeSearch:self.window firstLetter:@"/"];
}

- (XVimEvaluator*)DOT{
    [[XVim instance] startRepeat];
    XVimString *repeatRegister = [[XVim instance] repeatRegister];
    TRACE_LOG(@"Repeat:%@", repeatRegister);
    
    NSMutableArray* stack = [[[NSMutableArray alloc] init] autorelease];
    
    if( self.numericMode ){
        // Input numeric args if dot command has numeric arg
        XVimString* nums = [NSString stringWithFormat:@"%ld", (unsigned long)self.numericArg];
        for( XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(nums) ){
            [self.window handleKeyStroke:stroke onStack:stack];
        }
    }
    
    BOOL nonNumFound = NO;
    for( XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(repeatRegister) ){
        // TODO: This skips numeric args in repeat regisger if numericArg is specified.
        //       But if numericArg is not begining of the input (such as d3w) this never skips it.
        //       We have to also correctly handle "f3" not to skip the number.
        if( !nonNumFound && self.numericMode && [stroke isNumeric]){
            // Skip numeric arg
            continue;
        }
        nonNumFound = YES;
        [self.window handleKeyStroke:stroke onStack:stack];
    }
    [[XVim instance] endRepeat];
    return nil;
}

- (XVimEvaluator*)TILDE{
    XVimSourceView* view = [self sourceView];
    [view swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)DEL{
    [[self sourceView] moveBackward];
	return nil;
}

- (XVimEvaluator*)ForwardDelete{
	return [self x];
}

-(XVimEvaluator*)Pageup{
    return [self C_b];
}

-(XVimEvaluator*)Pagedown{
    return [self C_f];
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    // in normal mode
    // move the a cursor to end of motion. We ignore the motion type.
    XVimSourceView* view = [self sourceView];
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = to;
    [view move:m];
    return nil;
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    [[self sourceView] move:motion];
    return nil;
}

// There are fewer invalid keys than valid ones so make a list of invalid keys.
// This can always be changed to a set of valid keys in the future if need be.
//static NSArray *_invalidRepeatKeys;
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    /*
    if (_invalidRepeatKeys == nil){
        _invalidRepeatKeys =
        [[NSArray alloc] initWithObjects:
         [NSValue valueWithPointer:@selector(m)],
         [NSValue valueWithPointer:@selector(C_r)],
         [NSValue valueWithPointer:@selector(u)],
         [NSValue valueWithPointer:@selector(v)],
         [NSValue valueWithPointer:@selector(V)],
         [NSValue valueWithPointer:@selector(C_v)],
         [NSValue valueWithPointer:@selector(AT)],
         [NSValue valueWithPointer:@selector(COLON)],
         [NSValue valueWithPointer:@selector(DOT)],
         [NSValue valueWithPointer:@selector(QUESTION)],
         [NSValue valueWithPointer:@selector(SLASH)],
         nil];
    }
    NSValue *keySelector = [NSValue valueWithPointer:[keyStroke selectorForInstance:self]];
    if (keySelector == [NSValue valueWithPointer:@selector(q:)]) {
        return REGISTER_IGNORE;
    } else if (xregister.isRepeat) {
        // DOT command register
        if ([keyStroke classImplements:[XVimNormalEvaluator class]]) {
            if ([_invalidRepeatKeys containsObject:keySelector] == NO) {
                [xregister clear];
                if( [self numericArg] >= 2 ){
                    NSString* str = [NSString stringWithFormat:@"%ld",[self numericArg]];
                    for( NSUInteger i = 0; i < str.length; ++i ){
                        // FIXME: This code is temprarily commented out to refactor
                        //NSString* s1 = [str substringWithRange:NSMakeRange(i, 1)];
                        // XVimKeyStroke* keyStroke = [XVimKeyStroke fromNotation:s1];
                        //[xregister appendKeyEvent:keyStroke];
                    }
                }
                return REGISTER_APPEND;
            }
        }
    }
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
     */
    return REGISTER_APPEND;
}

@end
