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

- (id)init
{
	[super initWithContext:[[XVimEvaluatorContext alloc] init]];
	return self;
}
	 
- (id)initWithContext:(XVimEvaluatorContext*)context
{
	[super initWithContext:context];
	return self;
}

-(id)initWithContext:(XVimEvaluatorContext*)context
		playbackRegister:(XVimRegister*)xregister
{
	self = [super initWithContext:context];
    if (self) {
		_playbackRegister = xregister;
    }
    return self;
}

- (void)becameHandlerInWindow:(XVimWindow*)window
{	
	[[window sourceView] adjustCursorPosition];
	[super becameHandlerInWindow:window];
	
    if (_playbackRegister) {
		[[XVim instance] setLastPlaybackRegister:_playbackRegister];
        [_playbackRegister playbackWithHandler:window withRepeatCount:[self numericArg]];
        _playbackRegister = nil;
    }
}

- (NSString*)modeString {
    return @"";
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NORMAL];
}

/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////

// Command which results in cursor motion should be implemented in XVimMotionEvaluator

- (XVimEvaluator*)a:(XVimWindow*)window{
    // if we are at the end of a line. the 'a' acts like 'i'. it does not start inserting on
   // next line. it appends to the current line
    // A cursor should not be on the new line break letter in Vim(Except empty line).
    // So the root solution is to prohibit a cursor be on the newline break letter.
    XVimSourceView* view = [window sourceView];
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    if (!([view isEOF:idx] || [view isNewLine:idx]))
	{
		[view moveForward];
    } 
	return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

- (XVimEvaluator*)A:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger end = [view tailOfLine:r.location];
    [view setSelectedRange:NSMakeRange(end,0)];
    [view scrollTo:[window insertionPoint]];
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_b:(XVimWindow*)window{
    NSUInteger next = [[window sourceView] pageBackward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [[window sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c:(XVimWindow*)window{
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
														 insertModeAtCompletion:TRUE];
    return [[XVimDeleteEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"c"]
										 operatorAction:action 
											 withParent:self
								 insertModeAtCompletion:TRUE];
}

// 'C' works similar to 'D' except that once it's done deleting
// it should go into insert mode
- (XVimEvaluator*)C:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSRange range = [view selectedRange];
    NSUInteger count = [self numericArg];
    NSUInteger to = range.location;
    NSUInteger column = [view columnNumber:to];
    to = [view nextLine:range.location column:column count:count-1 option:MOTION_OPTION_NONE];
    NSUInteger eol = [view endOfLine:to];
    
    if (eol == NSNotFound && to != range.location){
        // This is blank line.
        // If the start and end point is not the same, the end position is before the blank line.
        eol = to-1;
    }
    
    if( eol != NSNotFound ){
        [view setSelectedRangeWithBoundsCheck:range.location To:eol+1];
        if( ![view isEOF:range.location] ){
			// cut with selection with {EOF,0} cause exception. This is a little strange since  setSelectedRange with {EOF,0} does not cause any exception...
            [view deleteTextIntoYankRegister:[self yankRegister]]; 
        }
    }
    
    // Go to insert 
    NSUInteger end = [view tailOfLine:[view selectedRange].location];
    [view setSelectedRange:NSMakeRange(end,0)];
    return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_d:(XVimWindow*)window{
    NSUInteger next = [[window sourceView] halfPageForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [[window sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)C_y:(XVimWindow*)window{
    NSUInteger next = [[window sourceView] lineBackward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [[window sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)C_e:(XVimWindow*)window{
    NSUInteger next = [[window sourceView] lineForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [[window sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)d:(XVimWindow*)window{
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
														 insertModeAtCompletion:NO];	
    return [[XVimDeleteEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"d"]
										 operatorAction:action 
											 withParent:self
								 insertModeAtCompletion:FALSE];
}

- (XVimEvaluator*)D:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSRange range = [view selectedRange];
    NSUInteger count = [self numericArg];
    NSString *text = [view string];
    NSUInteger to = range.location;
    for (; to < text.length && count > 0; ++to) {
        unichar c = [text characterAtIndex:to];
        if (isNewLine(c)) {
            --count;
        }
    }

    NSUInteger from = range.location;
    NSUInteger head = [view headOfLine:range.location];
    if (head != NSNotFound && [self numericArg] > 1 && !isWhiteSpace([text characterAtIndex:from])){
        for (; from >= head; --from){
            unichar c = [text characterAtIndex:from-1];
            if (isNewLine(c)){
                --from;
                break;
            }
            if (!isWhiteSpace(c)){
                break;
            }
        }
    }
    
    NSUInteger length = to - from;
    if (![view isEOF:to]){
        length -= 1;
    }
 
    if (length > 0){
        [view setSelectedRange:NSMakeRange(from, length)];
        [view deleteTextIntoYankRegister:[self yankRegister]];
        
        // Bounds check
        if (from == range.location && ![view isBlankLine:from]){
            --range.location;
        }
        
        [view setSelectedRange:NSMakeRange(range.location, 0)];
    }
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_f:(XVimWindow*)window{
    NSUInteger next = [[window sourceView] pageForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [[window sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)C_g:(XVimWindow*)window{
    // process
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

- (XVimEvaluator*)g:(XVimWindow*)window{
    return [[XVimGActionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"g"]
												  parent:self];
}

- (XVimEvaluator*)i:(XVimWindow*)window{
    // Go to insert 
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

- (XVimEvaluator*)I:(XVimWindow*)window{
    NSRange range = [[window sourceView] selectedRange];
    NSUInteger head = [[window sourceView] headOfLineWithoutSpaces:range.location];
    if( NSNotFound == head ){
        return [self A:window]; // If its blankline or has only whitespaces'I' works line 'A'
    }
    [self _motionFixedFrom:range.location To:head Type:CHARACTERWISE_INCLUSIVE inWindow:window];
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

// For 'J' (join line) bring the line up from below. all leading whitespac 
// of the line joined in should be stripped and then one space should be inserted 
// between the joined lines
- (XVimEvaluator*)J:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSUInteger repeat = [self numericArg];
    //if( 1 != repeat ){ repeat--; }
    NSRange r = [view selectedRange];
    BOOL addSpace = YES;
    for( NSUInteger i = 0 ; i < repeat ; i++ ){
        if( [view isBlankLine:r.location] ){
            [view deleteForward];
            continue;
        }
        
        if( [view isWhiteSpace:[view endOfLine:r.location]] ){
            // since the line is not empty, we do not need to check if its NSNotFound
            addSpace = NO;
        }
        
        NSUInteger nextnewline;
        nextnewline = [view nextNewLine:r.location];
        if( NSNotFound == nextnewline ){
            // Nothing to do
            break;
        }
        
        [view setSelectedRange:NSMakeRange(nextnewline,0)];
        [view deleteForward];
        NSRange cursorAfterConcatenate = [view selectedRange]; // After concatenate, the cursor position get back to this pos.
        if( addSpace ){
            [view insertText:@" "];
        }
        NSUInteger curLocation = [view selectedRange].location;
        
        NSUInteger nonblank = [view nextNonBlankInALine:[view selectedRange].location];
        if( NSNotFound == nonblank ){
            if( ![view isNewLine:curLocation] && [view isEOF:curLocation]){
                [view setSelectedRangeWithBoundsCheck:curLocation To:[view tailOfLine:curLocation]];
                [view deleteText];
            }else{
                // Blank line. Nothing todo
            }
        }else{
            if( curLocation != nonblank ){
                [view setSelectedRangeWithBoundsCheck:[view selectedRange].location To:nonblank];
                [view deleteText];
            }else{
                // No white spaces in next line.
            }
        }
        [view setSelectedRange:cursorAfterConcatenate];
    }
    return nil;
}

// Should be moved to XVimMotionEvaluator

 - (XVimEvaluator*)m:(XVimWindow*)window{
    // 'm{letter}' sets a local mark.
	return [[XVimMarkSetEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"m"]
												  parent:self];
}

- (XVimEvaluator*)o:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSUInteger l = [view selectedRange].location;
    NSUInteger tail = [view tailOfLine:l];
    [view setSelectedRange:NSMakeRange(tail,0)];
    [view insertNewline];
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

- (XVimEvaluator*)O:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSUInteger l = [view selectedRange].location;
    NSUInteger head = [view headOfLine:l];
    if( NSNotFound == head ){
        head = l;
    }
    if( 0 != head ){
        [view setSelectedRange:NSMakeRange(head-1,0)];
        [view insertNewline];
    }else{
        
        [view setSelectedRange:NSMakeRange(head,0)];
        [view insertNewline];
        NSUInteger prev = [view prevLine:[view selectedRange].location column:0 count:1 option:MOTION_OPTION_NONE];
        [view setSelectedRange:NSMakeRange(prev,0)];
    }
    return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

- (XVimEvaluator*)C_o:(XVimWindow*)window{
    [NSApp sendAction:@selector(goBackInHistoryByCommand:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)C_i:(XVimWindow*)window{
    [NSApp sendAction:@selector(goForwardInHistoryByCommand:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)p:(XVimWindow*)window{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    // TODO: This does not work when the text is copied from line which includes EOF since it does not have newline.
    //       If we want to treat the behaviour correctly we should prepare registers to copy and create an attribute to keep 'linewise'
    
    // TODO: dw of a word at the end of a line does not subsequently 'p' back correctly but that's
    // because dw is not working quite right it seems
    XVimSourceView* view = [window sourceView];
    NSUInteger loc = [view selectedRange].location;
    NSString *text = [[XVim instance] pasteText:[self yankRegister]];
    if (text.length > 0){
        unichar uc = [text characterAtIndex:[text length] -1];
		BOOL linewise = [[NSCharacterSet newlineCharacterSet] characterIsMember:uc];
        if (linewise) {
            if( [view isBlankLine:loc] && ![view isEOF:loc]){
                [view setSelectedRange:NSMakeRange(loc+1,0)];
            }else{
                NSUInteger newline = [view nextNewLine:loc];
                if( NSNotFound == newline ){
                    // add newline at EOF
                    [view setSelectedRange:NSMakeRange([[view string]length], 0)];
                    [view insertNewline];
                }else{
                    [view setSelectedRange:NSMakeRange(newline+1, 0)];
                }
            }
        } else {
			if (![view isNewLine:loc]) {
				[view moveForward];
			}
        }
		
		NSUInteger cursorLocation = [view selectedRange].location;
        for(NSUInteger i = 0; i < [self numericArg]; i++ ){
            [view insertText:text];
        }
		
		// Adjust cursor position
		if (!linewise) {
			cursorLocation += [text length] - 1;
		} else {
			cursorLocation = [view skipWhiteSpace:cursorLocation];
		}
		[view setSelectedRangeWithBoundsCheck:cursorLocation To:cursorLocation];
    }
    return nil;
}

- (XVimEvaluator*)P:(XVimWindow*)window{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    XVimSourceView* view = [window sourceView];
    NSString *text = [[XVim instance] pasteText:[self yankRegister]];
    if (text.length > 0){
        unichar uc = [text characterAtIndex:[text length] -1];
		BOOL linewise = [[NSCharacterSet newlineCharacterSet] characterIsMember:uc];
        if (linewise) {
            NSUInteger b = [view headOfLine:[view selectedRange].location];
            if( NSNotFound != b ){
                [view setSelectedRange:NSMakeRange(b,0)];
            }
        }
		NSUInteger loc = [view selectedRange].location;
        for(NSUInteger i = 0; i < [self numericArg]; i++ ){
            [view insertText:text];
        }
		
		NSUInteger cursorLocation = 0;
		if (linewise) {
			cursorLocation = [view skipWhiteSpace:loc];
		} else {
			cursorLocation = loc + [text length] - 1;
		}
		
		[view setSelectedRangeWithBoundsCheck:cursorLocation To:cursorLocation];
    }
    return nil;
}

- (XVimEvaluator*)q:(XVimWindow*)window{
    XVim *xvim = [XVim instance];
    if (xvim.recordingRegister != nil){
        [window stopRecordingRegister:xvim.recordingRegister];
        return nil;
    }
    
    XVimEvaluator *eval = [[XVimRegisterEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"q"]
																  parent:self
															  completion:^ XVimEvaluator* (NSString* rname, XVimEvaluatorContext *context) {
		XVimRegister *xregister = [[XVim instance] findRegister:rname];
        if (xregister && xregister.isReadOnly == NO) {
            [window recordIntoRegister:xregister];
        } else {
            [[XVim instance] ringBell];
        }
		return nil;
	}];
	
	return eval;
}

- (XVimEvaluator*)C_r:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
		[view redo];
    }
    // Redo should not keep anything selected
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, 0)];
	[view adjustCursorPosition];
    return nil;
}

- (XVimEvaluator*)r:(XVimWindow*)window{
	XVimEvaluatorContext *context = [XVimEvaluatorContext contextWithNumericArg:[self numericArg]];
	[context setArgumentString:@"r"];
	
    return [[XVimInsertEvaluator alloc] initWithContext:context
											oneCharMode:YES];
}

- (XVimEvaluator*)s:(XVimWindow*)window{
    XVimSourceView *view = [window sourceView];
    NSRange r = [view selectedRange];
	
	// Set range to replace, ensuring we don't run over the end of the buffer
	NSUInteger endi = r.location + [self numericArg];
	NSUInteger maxi = [[view string] length];
	endi = MIN(endi, maxi);
	NSRange replacementRange = NSMakeRange(r.location, endi - r.location);
	
    [view setSelectedRange:replacementRange];
	
	// Xcode crashes if we cut a zero length selection
	if (replacementRange.length > 0)
	{
		[view insertText:@"" replacementRange:replacementRange]; // Can't use del here since we may want to wind up at end of line
	}
	
    return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
											oneCharMode:NO];
}

// "S" is Synonym for "cc"
- (XVimEvaluator*)S:(XVimWindow*)window{
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
														 insertModeAtCompletion:TRUE];

	if( [self numericArg] < 1 )
		return nil;

    XVimSourceView* view = [window sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:[self numericArg]-1 option:MOTION_OPTION_NONE];
    return [action motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}

- (XVimEvaluator*)u:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [view undo];
    }

    // Undo should not keep anything selected
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, 0)];
	[view adjustCursorPosition];
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_u:(XVimWindow*)window{
    NSUInteger next = [[window sourceView] halfPageBackward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [[window sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    return [[XVimVisualEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
												   mode:MODE_CHARACTER];
}

- (XVimEvaluator*)V:(XVimWindow*)window{
    return [[XVimVisualEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
												   mode:MODE_LINE]; 
}

- (XVimEvaluator*)C_v:(XVimWindow*)window{
    // Block selection
    return nil;
}

- (XVimEvaluator*)C_w:(XVimWindow*)window{
    return [[XVimWindowEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"^W"]
												 parent:self];
}

- (XVimEvaluator*)x:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSString* s = [view string];
    // note: in vi you are not supposed to move beyond the end of a line when doing "x" operations
    // it's that way on purpose. this allows you to hit a bunch of x's in a row and not worry about 
    // accidentally joining the next line into the current line.
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
	if (idx == s.length) { return nil; }
	
    for( NSUInteger i = 0 ; idx < s.length && i < [self numericArg]; i++,idx++ ){
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx]]) {
            // if at the end of line, and are just doing a single x it's like doing X
            if ([self numericArg] == 1) {
                if (idx > 0 && ![[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx-1]]) {
                    [view moveBackwardAndModifySelection]; 
                }
            }
            break;
        }
        [view moveForwardAndModifySelection];
    }
    [view deleteTextIntoYankRegister:[self yankRegister]];
    return nil;
}

// like 'x" but it goes backwards instead of forwards
- (XVimEvaluator*)X:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSString* s = [view string];
    // note: in vi you are not supposed to move beyond the start of a line when doing "X" operations
    // it's that way on purpose. this allows you to hit a bunch of X's in a row and not worry about 
    // accidentally joining the current line up into the previous line.
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    for( NSUInteger i = 0 ; idx > 0 && i < [self numericArg]; i++,idx-- ){
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx-1]])
            break;
        [view moveBackwardAndModifySelection]; 
    }
    [view deleteTextIntoYankRegister:[self yankRegister]];
    return nil;
}

- (XVimEvaluator*)Y:(XVimWindow*)window{
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] initWithYankRegister:[self yankRegister]];
    XVimYankEvaluator* yank = [[XVimYankEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"y"]
									   operatorAction:operatorAction 
										   withParent:self];
    return [yank y:window];
}

- (XVimEvaluator*)y:(XVimWindow*)window{
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] initWithYankRegister:[self yankRegister]];
    return [[XVimYankEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"y"]
									   operatorAction:operatorAction 
										   withParent:self];
}

- (XVimEvaluator*)AT:(XVimWindow*)window
{
    XVimEvaluator *eval = [[XVimRegisterEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"@"]
																  parent:self
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
	
	return eval;
}

- (XVimEvaluator*)DQUOTE:(XVimWindow*)window
{
    XVimEvaluator *eval = [[XVimRegisterEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"\""]
																									 parent:self
																								 completion:^ XVimEvaluator* (NSString* rname, XVimEvaluatorContext *context) 
	{
		XVimRegister *xregister = [[XVim instance] findRegister:rname];
        if (xregister.isReadOnly == NO || [xregister.displayName isEqualToString:@"%"] )
		{
			[context setYankRegister:xregister];
			[context appendArgument:rname];
            return [[XVimNormalEvaluator alloc] initWithContext:context];
        }
            
		[[XVim instance] ringBell];
		return nil;
	}];
	return eval;
}

- (XVimEvaluator*)EQUAL:(XVimWindow*)window{
    XVimOperatorAction *operatorAction = [[XVimEqualAction alloc] init];
    return [[XVimEqualEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"="]
										operatorAction:operatorAction 
											withParent:self];
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
	XVimOperatorAction *operatorAction = [[XVimShiftAction alloc] initWithUnshift:NO];
    XVimShiftEvaluator* eval =  [[XVimShiftEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@">"]
															 operatorAction:operatorAction 
																 withParent:self
																	unshift:NO];
    return eval;
}

- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window{
	XVimOperatorAction *operatorAction = [[XVimShiftAction alloc] initWithUnshift:YES];
    XVimShiftEvaluator* eval =  [[XVimShiftEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"<"]
															 operatorAction:operatorAction 
																 withParent:self
																	unshift:YES];
    return eval;
    
}

- (XVimEvaluator*)HT:(XVimWindow*)window{
    [[window sourceView] selectNextPlaceholder];
    return nil;
}

- (XVimEvaluator*)COLON:(XVimWindow*)window{
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
																	 parent:self 
															   firstLetter:@":" 
																   history:[[XVim instance] exCommandHistory]
																completion:^ XVimEvaluator* (NSString* command) 
                           {
                               XVimExCommand *excmd = [[XVim instance] excmd];
                               [excmd executeCommand:command inWindow:window];
                               return nil;
                           }
                                                                onKeyPress:nil];
	
	return eval;
}

- (XVimEvaluator*)executeSearch:(XVimWindow*)window firstLetter:(NSString*)firstLetter 
{
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
																	 parent:self 
															   firstLetter:firstLetter
																   history:[[XVim instance] searchHistory]
																completion:^ XVimEvaluator* (NSString *command)
						   {
							   XVimSearch *searcher = [[XVim instance] searcher];
							   XVimSourceView *sourceView = [window sourceView];
							   NSRange found = [searcher executeSearch:command 
															   display:[command substringFromIndex:1] 
																  from:[window insertionPoint] 
															  inWindow:window];
							   //Move cursor and show the found string
							   if (found.location != NSNotFound) {
								   [sourceView setSelectedRange:NSMakeRange(found.location, 0)];
								   [sourceView scrollTo:[window insertionPoint]];
								   [sourceView showFindIndicatorForRange:found];
							   } else {
								   [window errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchDisplayString] ringBell:TRUE];
							   }
							   return nil;
						   }
                                                                onKeyPress:^void(NSString *command)
                           {
                               XVimOptions *options = [[XVim instance] options];
                               if (options.incsearch){
                                   XVimSearch *searcher = [[XVim instance] searcher];
                                   XVimSourceView *sourceView = [window sourceView];
                                   NSRange found = [searcher executeSearch:command 
																   display:[command substringFromIndex:1]
																	  from:[window insertionPoint] 
																  inWindow:window];
                                   //Move cursor and show the found string
                                   if (found.location != NSNotFound) {
                                       [sourceView scrollTo:found.location];
                                       [sourceView showFindIndicatorForRange:found];
                                   }
                               }
                           }];
	return eval;
}

- (XVimEvaluator*)QUESTION:(XVimWindow*)window{
	return [self executeSearch:window firstLetter:@"?"];
}

- (XVimEvaluator*)SLASH:(XVimWindow*)window{
	return [self executeSearch:window firstLetter:@"/"];
}

- (XVimEvaluator*)DOT:(XVimWindow*)window{
    XVimRegister *repeatRegister = [[XVim instance] findRegister:@"repeat"];
    [repeatRegister playbackWithHandler:window withRepeatCount:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
	NSRange replacementRange = [view selectedRange];
	replacementRange.length = [self numericArg];
	[view clampRangeToEndOfLine:&replacementRange];
	[view toggleCaseForRange:replacementRange];
	return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    // in normal mode
    // move the a cursor to end of motion. We ignore the motion type.
    XVimSourceView* view = [window sourceView];
    NSRange r = NSMakeRange(to, 0);
    [view setSelectedRange:r];
    [view adjustCursorPosition];
    [view scrollTo:[window insertionPoint]];
    return nil;
    //return [self withNewContext];
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

- (XVimEvaluator*)DEL:(XVimWindow*)window
{
	return [self h:window];
}

- (XVimEvaluator*)ForwardDelete:(XVimWindow*)window
{
	return [self x:window];
}

-(XVimEvaluator*)Pageup:(XVimWindow*)window{
    return [self C_b:(XVimWindow*)window];
}

-(XVimEvaluator*)Pagedown:(XVimWindow*)window{
    return [self C_f:(XVimWindow*)window];
}
@end
