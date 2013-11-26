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
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimKeymapProvider.h"
#import "Logger.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimOptions.h"
#import "XVimRecordingEvaluator.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimMotion.h"
#import "XVimView.h"
#import "XVimJoinEvaluator.h"

@interface XVimNormalEvaluator() {
	__weak XVimRegister *_playbackRegister;
}
@end

@implementation XVimNormalEvaluator

- (void)becameHandler{
    [super becameHandler];
    self.currentView.selectionMode = XVIM_VISUAL_NONE;
}

- (NSString*)modeString {
    return @"";
}

- (XVIM_MODE)mode{
    return XVIM_MODE_NORMAL;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_NORMAL];
}

/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////

// Command which results in cursor motion should be implemented in XVimMotionEvaluator

- (XVimEvaluator*)a{
	return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_APPEND] autorelease];
}

- (XVimEvaluator*)A{
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_APPEND_EOL] autorelease];
}

- (XVimEvaluator*)C_a{
    if ([self.currentView doIncrementNumber:(int64_t)self.numericArg]) {
        [[XVim instance] fixOperationCommands];
    } else {
        [[XVim instance] cancelOperationCommands];
    }
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_b{
    [self.currentView scrollPageBackward:self.numericArg];
    return nil;
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c{
    [self.argumentString appendString:@"c"];
    return [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES] autorelease];
}

- (XVimEvaluator*)C{
    // Same as c$
    XVimDeleteEvaluator* d = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES] autorelease];
    d.parent = self;
    return [d performSelector:@selector(DOLLAR)];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_d{
    [self.currentView scrollHalfPageForward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)d{
	//XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister] insertModeAtCompletion:NO];
    [self.argumentString appendString:@"d"];
    return [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:FALSE] autorelease];
}

- (XVimEvaluator*)D{
    // Same as d$
    XVimDeleteEvaluator* eval = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:NO] autorelease];
    eval.parent = self;
    return [eval performSelector:@selector(DOLLAR)];
}

- (XVimEvaluator*)C_e{
    [self.currentView scrollLineForward:self.numericArg];
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_f{
    [self.currentView scrollPageForward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)C_g
{
    // process
    XVimWindow  *window = self.window;
    XVimBuffer  *buffer = window.currentBuffer;
    XVimView    *xview  = self.currentView;
    XVimPosition pos    = xview.insertionPosition;

    NSUInteger numberOfLines = [buffer numberOfLines];
    NSURL *documentURL = buffer.document.fileURL;

	if ([documentURL isFileURL]) {
		NSString *text = [NSString stringWithFormat:@"%@   line %ld of %ld --%d%%-- col %ld",
                          documentURL.path, pos.line, numberOfLines,
                          (int)((CGFloat)pos.line*100.0/(CGFloat)numberOfLines), pos.column + 1 ];
        
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
    if( [childEvaluator.key.toSelectorString isEqualToString:@"SEMICOLON"] ){
        XVimMark* mark = [[XVim instance].marks markForName:@"." forDocument:self.window.currentBuffer.document];
        return [self jumpToMark:mark firstOfLine:NO];
    }else{
        if( childEvaluator.motion != nil ){
            return [self _motionFixed:childEvaluator.motion];
        }
    }
    return nil;
}

- (XVimEvaluator*)i{
    // Go to insert 
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)I{
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_BEFORE_FIRST_NONBLANK] autorelease];
}

- (XVimEvaluator*)J{
    XVimJoinEvaluator* eval = [[[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:YES] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, self.numericArg)];
}

// Should be moved to XVimMotionEvaluator

- (XVimEvaluator*)m{
    // 'm{letter}' sets a local mark.
    [self.argumentString appendString:@"m"];
	return [[[XVimMarkSetEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)o{
    [self.currentView insertNewlineBelowAndInsertWithIndent];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)O{
    [self.currentView insertNewlineAboveAndInsertWithIndent];
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
    XVimRegister* reg = [[[XVim instance] registerManager] registerByName:self.yankRegister];
    [self.currentView doPut:reg.string withType:reg.type afterCursor:YES count:[self numericArg]];
    [[XVim instance] fixOperationCommands];
    return nil;
}

- (XVimEvaluator*)P{
    XVimRegister* reg = [[[XVim instance] registerManager] registerByName:self.yankRegister];
    [self.currentView doPut:reg.string withType:reg.type afterCursor:NO count:[self numericArg]];
    [[XVim instance] fixOperationCommands];
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
        return [[[XVimRecordingEvaluator alloc] initWithWindow:self.window withRegister:childEvaluator.reg] autorelease];
    }
    [[XVim instance] ringBell];
    return nil;
}

- (XVimEvaluator*)onComplete_Recording:childEvaluator{
    return nil;
}

- (XVimEvaluator*)C_r
{
    XVimBuffer *buffer = self.window.currentBuffer;

    for (NSUInteger i = 0; i < [self numericArg]; i++) {
        [buffer.undoManager redo];
    }
    return nil;
}

- (XVimEvaluator*)r{
	[self.argumentString appendString:@"r"];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:YES mode:XVIM_INSERT_DEFAULT] autorelease];
}

- (XVimEvaluator*)s{
    // Same as cl
    XVimDeleteEvaluator* eval = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES] autorelease];
    eval.parent = self;
    return [eval performSelector:@selector(l)];
}

// "S" is Synonym for "cc"
- (XVimEvaluator*)S{
    XVimDeleteEvaluator* d = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES] autorelease];
    d.parent = self;
    return [d performSelector:@selector(c)];
}

- (XVimEvaluator*)u
{
    XVimBuffer *buffer = self.window.currentBuffer;

    for (NSUInteger i = 0; i < [self numericArg]; i++) {
        [buffer.undoManager undo];
    }
    [self.currentView moveCursorToIndex:self.currentView.insertionPoint];
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_u{
    [self.currentView scrollHalfPageBackward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)v{
    if( XVim.instance.isRepeating ){
        return [[[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window] autorelease];
    }else{
        return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_CHARACTER] autorelease];
    }
}

- (XVimEvaluator*)V{
    if( XVim.instance.isRepeating ){
        return [[[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window] autorelease];
    }else{
        return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_LINE] autorelease];
    }
}

- (XVimEvaluator*)C_v{
    if( XVim.instance.isRepeating ){
        return [[[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window] autorelease];
    }else{
        return [[[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_BLOCK]  autorelease];
    }
}

- (XVimEvaluator*)C_w{
    [self.argumentString appendString:@"^W"];
    return [[[XVimWindowEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)x{
    // Same as dl
    XVimDeleteEvaluator* eval = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:NO] autorelease];
    eval.parent = self;
    return [eval performSelector:@selector(l)];
}

// like 'x" but it goes backwards instead of forwards
- (XVimEvaluator*)X{
    XVimDeleteEvaluator* eval = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:NO] autorelease];
    eval.parent = self;
    return [eval performSelector:@selector(h)];
}

- (XVimEvaluator*)C_x{
    if ([self.currentView doIncrementNumber:-(int64_t)self.numericArg]) {
        [[XVim instance] fixOperationCommands];
    } else {
        [[XVim instance] cancelOperationCommands];
    }
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
    [self.currentView scrollLineBackward:self.numericArg];
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
    [[XVim instance].registerManager registerExecuted:childEvaluator.reg];
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

- (XVimEvaluator*)C_RSQUAREBRACKET{
    [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)HT{
    [self.currentView selectNextPlaceholder];
    return nil;
}

- (XVimEvaluator*)COLON{
	XVimEvaluator *eval = [[[XVimCommandLineEvaluator alloc] initWithWindow:self.window
                                                                firstLetter:@":"
                                                                    history:[[XVim instance] exCommandHistory]
                                                                 completion:^ XVimEvaluator* (NSString* command, id* result)
                           {
                               XVimExCommand *excmd = [[XVim instance] excmd];
                               [excmd executeCommand:command inWindow:self.window];
                               return nil;
                           }
                                                                 onKeyPress:nil] autorelease];
	
	return eval;
}

- (XVimEvaluator*)DOT{
    [[XVim instance] startRepeat];
    XVimString *repeatRegister = [[XVim instance] lastOperationCommands];
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
        //       We have to also correctly handle "df3" not to skip the number.
        if( !nonNumFound && self.numericMode && [stroke isNumeric]){
            // Skip numeric arg
            continue;
        }
        nonNumFound = YES;
        TRACE_LOG("Feeding stroke: %@", stroke);
        [self.window handleKeyStroke:stroke onStack:stack];
    }
    [[XVim instance] endRepeat];
    return nil;
}

- (XVimEvaluator*)TILDE{
    [self.argumentString appendString:@"~"];
    XVimMotion *m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, self.numericArg);
    [self.currentView doSwapCharacters:m mode:XVIM_BUFFER_SWAP_CASE];
    [XVim.instance fixOperationCommands];
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

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    [self.currentView moveCursorWithMotion:motion];
    return nil;
}

@end
