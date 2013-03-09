//
//  XVimNormalEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//


#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimSearchLineEvaluator.h"
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

@interface XVimNormalEvaluator() {
	__weak XVimRegister *_playbackRegister;
}
@end

@implementation XVimNormalEvaluator

-(id)initWithContext:(XVimEvaluatorContext*)context withWindow:(XVimWindow *)window playbackRegister:(XVimRegister*)xregister{
	self = [super initWithContext:context withWindow:window];
    if (self) {
		_playbackRegister = xregister;
    }
    return self;
}

- (void)becameHandler{
    if (_playbackRegister) {
		[[XVim instance] setLastPlaybackRegister:_playbackRegister];
        [_playbackRegister playbackWithHandler:self.window withRepeatCount:[self numericArg]];
        _playbackRegister = nil;
    }
}

- (NSString*)modeString {
    return @"";
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
	return [[[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window] autorelease];
}

- (XVimEvaluator*)A{
    XVimSourceView* view = [self sourceView];
    [view appendAtEndOfLine];
    return [[[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window] autorelease];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_b{
    [[self sourceView] scrollHalfPageBackward:[self numericArg]];
    return nil;
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c{
	//XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister] insertModeAtCompletion:TRUE];
    return [[XVimDeleteEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"c"]
                                             withWindow:self.window
											 withParent:self
								 insertModeAtCompletion:TRUE];
}

// 'C' works similar to 'D' except that once it's done deleting
// it should go into insert mode
- (XVimEvaluator*)C{
    [self D];
    [[self sourceView] append];
    return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init] withWindow:self.window];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_d{
    [[self sourceView] scrollHalfPageForward:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)d{
	//XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister] insertModeAtCompletion:NO];
    return [[XVimDeleteEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"d"] withWindow:self.window withParent:self insertModeAtCompletion:FALSE];
}

- (XVimEvaluator*)D{
    XVimSourceView* view = [self sourceView];
    XVimMotion* m= XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]);
    [view delete:m];
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
    return [[XVimGActionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"g"] withWindow:self.window withParent:self];
}

- (XVimEvaluator*)i{
    // Go to insert 
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window];
}

- (XVimEvaluator*)I{
    [[self sourceView] insertBeforeFirstNonBlank];
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window];
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
	return [[XVimMarkSetEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"m"] withWindow:self.window withParent:self];
}

- (XVimEvaluator*)o{
    XVimSourceView* view = [self sourceView];
    [view insertNewlineBelow];
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window];
}

- (XVimEvaluator*)O{
    XVimSourceView* view = [self sourceView];
    [view insertNewlineAbove];
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window];
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
    XVimRegister* reg = [XVim instance].yankRegister;
    [view put:reg.string withType:reg.type afterCursor:YES count:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)P{
    XVimSourceView* view = [self sourceView];
    XVimRegister* reg = [XVim instance].yankRegister;
    [view put:reg.string withType:reg.type afterCursor:NO count:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)q{
    XVim *xvim = [XVim instance];
    if (xvim.recordingRegister != nil){
        [[self window] stopRecordingRegister:xvim.recordingRegister];
        return nil;
    }
    
    return [[XVimRecordingRegisterEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"q"] withWindow:self.window withParent:self];
}

- (XVimEvaluator*)C_r{
    XVimSourceView* view = [self sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
		[view redo];
    }
    return nil;
}

- (XVimEvaluator*)r{
	XVimEvaluatorContext *context = [XVimEvaluatorContext contextWithNumericArg:[self numericArg]];
	[context setArgumentString:@"r"];
    return [[XVimInsertEvaluator alloc] initWithContext:context withWindow:self.window oneCharMode:YES];
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
	
	// Xcode crashes if we cut a zero length selection
	if (replacementRange.length > 0){
		[view deleteText]; // Can't use del here since we may want to wind up at end of line
	}
	
    return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init] withWindow:self.window oneCharMode:NO];
}

// "S" is Synonym for "cc"
- (XVimEvaluator*)S{
    XVimDeleteEvaluator* d = [[[XVimDeleteEvaluator alloc] initWithContext:self.contextCopy withWindow:self.window withParent:self insertModeAtCompletion:YES] autorelease];
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
    return [[[XVimVisualEvaluator alloc] initWithContext:[[[XVimEvaluatorContext alloc] init] autorelease] withWindow:self.window mode:MODE_CHARACTER] autorelease];
}

- (XVimEvaluator*)V{
    return [[[XVimVisualEvaluator alloc] initWithContext:[[[XVimEvaluatorContext alloc] init] autorelease] withWindow:self.window mode:MODE_LINE] autorelease];
}

- (XVimEvaluator*)C_v{
    // Block selection
    return [[[XVimVisualEvaluator alloc] initWithContext:[[[XVimEvaluatorContext alloc] init] autorelease] withWindow:self.window mode:MODE_BLOCK]  autorelease];
}

- (XVimEvaluator*)C_w{
    return [[XVimWindowEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"^W"] withWindow:self.window withParent:self];
}

- (XVimEvaluator*)x{
    XVimSourceView* view = [self sourceView];
    XVimMotion* m= XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg]);
    [view delete:m];
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
    XVimYankEvaluator* yank = [[[XVimYankEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"y"] withWindow:self.window withParent:self] autorelease];
    return [yank y];
}

- (XVimEvaluator*)y{
    return [[[XVimYankEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"y"] withWindow:self.window withParent:self] autorelease];
}

- (XVimEvaluator*)C_y{
    [[self sourceView] scrollLineBackward:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)AT{
    XVimEvaluator *eval = [[[XVimRegisterEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"@"] withWindow:self.window withParent:self] autorelease];
    // FIXME
    /*
completion:^ XVimEvaluator* (NSString* rname, XVimEvaluatorContext *context)
                           {
                               XVim *xvim = [XVim instance];
                               XVimRegister *xregister = [rname isEqualToString:@"AT"] ? [xvim lastPlaybackRegister] : [xvim findRegister:rname];
                               
                               if (xregister && xregister.isReadOnly == NO) {
                                   return [[XVimNormalEvaluator alloc] initWithContext:[self contextCopy]
                                                                      playbackRegister:xregister];
                               } else {
                                   [xvim ringBell];
                                   return nil;
                               }
                           }];
	
     */
	return eval;
}

- (XVimEvaluator*)DQUOTE{
    return  [[[XVimRegisterEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"\""] withWindow:self.window withParent:self] autorelease];
}

- (XVimEvaluator*)EQUAL{
    return [[[XVimEqualEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"="] withWindow:self.window withParent:self] autorelease];
}

- (XVimEvaluator*)GREATERTHAN{
    XVimShiftEvaluator* eval =  [[[XVimShiftEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@">"] withWindow:self.window withParent:self unshift:NO] autorelease];
    return eval;
}

- (XVimEvaluator*)LESSTHAN{
    XVimShiftEvaluator* eval =  [[[XVimShiftEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"<"] withWindow:self.window withParent:self unshift:YES] autorelease];
    return eval;
    
}

- (XVimEvaluator*)HT{
    [[self sourceView] selectNextPlaceholder];
    return nil;
}

- (XVimEvaluator*)COLON{
	XVimEvaluator *eval = [[[XVimCommandLineEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
                                                                 withWindow:self.window
																	 withParent:self
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
	XVimEvaluator *eval = [[[XVimCommandLineEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
                                                                 withWindow:self.window
																	 withParent:self
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
    XVimRegister *repeatRegister = [[XVim instance] findRegister:@"repeat"];
    [repeatRegister playbackWithHandler:self.window withRepeatCount:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)TILDE{
    XVimSourceView* view = [self sourceView];
    [view swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
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
static NSArray *_invalidRepeatKeys;
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (_invalidRepeatKeys == nil){
        _invalidRepeatKeys =
        [[NSArray alloc] initWithObjects:
         [NSValue valueWithPointer:@selector(m:)],
         [NSValue valueWithPointer:@selector(C_r:)],
         [NSValue valueWithPointer:@selector(u:)],
         [NSValue valueWithPointer:@selector(v:)],
         [NSValue valueWithPointer:@selector(V:)],
         [NSValue valueWithPointer:@selector(C_v:)],
         [NSValue valueWithPointer:@selector(AT:)],
         [NSValue valueWithPointer:@selector(COLON:)],
         [NSValue valueWithPointer:@selector(DOT:)],
         [NSValue valueWithPointer:@selector(QUESTION:)],
         [NSValue valueWithPointer:@selector(SLASH:)],
         nil];
    }
    NSValue *keySelector = [NSValue valueWithPointer:[keyStroke selectorForInstance:self]];
    if (keySelector == [NSValue valueWithPointer:@selector(q:)]) {
        return REGISTER_IGNORE;
    } else if (xregister.isRepeat) {
        if ([keyStroke classImplements:[XVimNormalEvaluator class]]) {
            if ([_invalidRepeatKeys containsObject:keySelector] == NO) {
                return REGISTER_REPLACE;
            }
        }
    }
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
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
@end
