//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimInsertEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
#import "Logger.h"
#import "XVimEqualEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimYankEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimGVisualEvaluator.h"
#import "XVimRegisterEvaluator.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimOptions.h"
#import "XVim.h"
#import "XVimYankEvaluator.h"
#import "XVimShiftEvaluator.h"
#import "XVimSwapCharsEvaluator.h"
#import "XVimJoinEvaluator.h"
#import "XVimView.h"

static NSString* MODE_STRINGS[] = {@"", @"-- VISUAL --", @"-- VISUAL LINE --", @"-- VISUAL BLOCK --"};

@interface XVimVisualEvaluator(){
    BOOL _waitForArgument;
    XVimVisualInfo _initial;
}
@end

@implementation XVimVisualEvaluator 
- (id)initWithLastVisualStateWithWindow:(XVimWindow *)window{
    XVimBuffer     *buffer = window.currentBuffer;
    XVimVisualInfo *vi = &buffer->visualInfo;

    if (vi->mode == XVIM_VISUAL_NONE) {
        [window errorMessage:@"no previous visual state" ringBell:YES];
        [self release];
        return nil;
    }

    if ((self = [self initWithWindow:window])) {
        _initial = *vi;
    }
    return self;
}
    
- (id)initWithWindow:(XVimWindow *)window mode:(XVimVisualMode)mode {
    NSTextView *sourceView = window.currentView.textView;
    NSUInteger start = [[sourceView.selectedRanges objectAtIndex:0] rangeValue].location;
    NSUInteger end = NSMaxRange([sourceView.selectedRanges.lastObject rangeValue]);
    XVimBuffer *buffer = window.currentBuffer;

    if (end > start) {
        end--;
    }

	if (self = [self initWithWindow:window]) {
        _waitForArgument = NO;
        _initial.mode         = mode;
        _initial.start.line   = [buffer lineNumberAtIndex:start];
        _initial.start.column = [buffer columnOfIndex:start];
        _initial.end.line     = [buffer lineNumberAtIndex:end];
        _initial.end.column   = [buffer columnOfIndex:end];
        _initial.colwant      = _initial.end.column;

        if (sourceView.selectedRanges.count > 1) {
            // Treat it as block selection
            _initial.mode = XVIM_VISUAL_BLOCK;
        }
	}
    return self;
}

- (NSString*)modeString {
	return MODE_STRINGS[_initial.mode];
}

- (XVIM_MODE)mode{
    return XVIM_MODE_VISUAL;
}

- (void)becameHandler
{
    XVimView *xview = self.currentView;

    [super becameHandler];

    if (_initial.mode) {
        if (XVim.instance.isRepeating) {
            NSUInteger   columns = XVimVisualInfoColumns(&_initial);
            NSUInteger   lines   = XVimVisualInfoLines(&_initial);
            XVimPosition pos;

            xview.selectionMode = _initial.mode;
            pos = xview.insertionPosition;

            // When repeating we have to set initial selected range
            if (_initial.mode == XVIM_VISUAL_CHARACTER) {
                if (lines == 1) {
                    // Same number of character if in one line
                    pos.column += columns - 1;
                } else {
                    pos.line   += lines - 1;
                    pos.column  = _initial.start.line < _initial.end.line ? _initial.end.column : _initial.start.column;
                }
            } else if (_initial.mode == XVIM_VISUAL_LINE) {
                pos.line   += lines - 1;
            } else {
                // Use same number of lines/colums
                pos.column += columns - 1;
                pos.line   += lines - 1;
            }

            [xview moveCursorToPosition:pos];
        } else {
            [xview moveCursorToPosition:_initial.start];
            xview.selectionMode = _initial.mode;
            [xview moveCursorToPosition:_initial.end];
            // TODO: self.sourceView.preservedColumn = _initial.colwant;
        }
        if (_initial.end.column == XVimSelectionEOL) {
            [self performSelector:@selector(DOLLAR)];
        }
        _initial.mode = XVIM_VISUAL_NONE;
    }
}

- (void)didEndHandler{
    if (!_waitForArgument) {
        self.currentView.selectionMode = XVIM_VISUAL_NONE;
        // TODO:
        //[[[XVim instance] repeatRegister] setVisualMode:_mode withRange:_operationRange];
    }
    [super didEndHandler];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_VISUAL];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    if (!XVim.instance.isRepeating) {
        [self.currentView saveVisualInfoForBuffer:self.window.currentBuffer];
    }

    XVimEvaluator *nextEvaluator = [super eval:keyStroke];
    
    if ([XVimEvaluator invalidEvaluator] == nextEvaluator) {
        return self;
    } else {
        return nextEvaluator;
    }
}

- (XVimEvaluator*)a{
    // FIXME: doesn't work properly, especially in block mode
    self.onChildCompleteHandler = @selector(onComplete_ai:);
    [self.argumentString appendString:@"a"];
	return [[[XVimTextObjectEvaluator alloc] initWithWindow:self.window inner:NO] autorelease];
}

- (XVimEvaluator*)A{
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_APPEND] autorelease];
}

- (XVimEvaluator*)i{
    // FIXME: doesn't work properly, especially not in block mode
    self.onChildCompleteHandler = @selector(onComplete_ai:);
    [self.argumentString appendString:@"i"];
    return [[[XVimTextObjectEvaluator alloc] initWithWindow:self.window inner:YES] autorelease];
}


- (XVimEvaluator*)onComplete_ai:(XVimTextObjectEvaluator*)childEvaluator{
    XVimMotion *m = childEvaluator.motion;

    self.onChildCompleteHandler = nil;
    if (m.motion != MOTION_NONE) {
        return [self _motionFixed:m];
    }
    return self;
}

- (XVimEvaluator*)c{
    if (self.currentView.inBlockMode) {
        return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_BLOCK_KILL] autorelease];
    }
    XVimDeleteEvaluator* eval = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1)];
}

- (XVimEvaluator *)C{
    XVimView *xview = self.currentView;

    if (!xview.inBlockMode) {
        xview.selectionMode = XVIM_VISUAL_LINE;
        return [self c];
    }
    [self performSelector:@selector(DOLLAR)];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_BLOCK_KILL] autorelease];
}

- (XVimEvaluator*)C_b{
    [self.currentView scrollPageBackward:self.numericArg];
    return self;
}

- (XVimEvaluator*)C_d{
    [self.currentView scrollHalfPageForward:self.numericArg];
    return self;
}

- (XVimEvaluator*)d{
    XVimDeleteEvaluator* eval = [[[XVimDeleteEvaluator alloc] initWithWindow:self.window] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, 0)];
}

- (XVimEvaluator *)DEL{
    return [self d];
}

- (XVimEvaluator*)D{
    XVimView *xview = self.currentView;

    if (xview.inBlockMode) {
        [self performSelector:@selector(DOLLAR)];
    } else {
        xview.selectionMode = XVIM_VISUAL_LINE;
    }

    return [self d];
}

- (XVimEvaluator*)C_f{
    [self.currentView scrollPageForward:self.numericArg];
    return self;
}

- (XVimEvaluator*)g{
    [self.argumentString appendString:@"g"];
    self.onChildCompleteHandler = @selector(g_completed:);
    return [[[XVimGVisualEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator *)g_completed:(XVimEvaluator *)childEvaluator{
    if (childEvaluator == [XVimEvaluator invalidEvaluator]) {
        [self.argumentString setString:@""];
        return self;
    }
    return childEvaluator;
}

- (XVimEvaluator*)I{
    if (!self.currentView.inBlockMode) {
        return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_BEFORE_FIRST_NONBLANK] autorelease];
    }
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:XVIM_INSERT_DEFAULT] autorelease];
}

- (XVimEvaluator*)J{
    XVimJoinEvaluator* eval = [[[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:YES] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator*)m{
    // 'm{letter}' sets a local mark.
    [self.argumentString appendString:@"m"];
    self.onChildCompleteHandler = @selector(m_completed:);
	return [[[XVimMarkSetEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)m_completed:(XVimEvaluator*)childEvaluator{
    // Vim does not escape from Visual mode after mark is set by m command
    self.onChildCompleteHandler = nil;
    return self;
}

- (XVimEvaluator *)o{
    [self.currentView selectSwapCorners:NO];
    return self;
}

- (XVimEvaluator *)O{
    [self.currentView selectSwapCorners:YES];
    return self;
}

- (XVimEvaluator*)p{
    XVimRegister* reg = [[[XVim instance] registerManager] registerByName:self.yankRegister];
    [self.currentView doPut:reg.string withType:reg.type afterCursor:YES count:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)P{
    // Looks P works as p in Visual Mode.. right?
    return [self p];
}

- (XVimEvaluator *)r{
    [self.window errorMessage:@"{Visual}r{char} not implemented yet" ringBell:NO];
    return self;
}

- (XVimEvaluator *)R{
    return [self S];
}

- (XVimEvaluator*)s{
	// As far as I can tell this is equivalent to change
	return [self c];
}

- (XVimEvaluator *)S{
    XVimView *xview = self.currentView;

    if (!xview.inBlockMode) {
        xview.selectionMode = XVIM_VISUAL_LINE;
    }
    [self.window errorMessage:@"{Visual}S not implemented yet" ringBell:NO];
    return self;
}

- (XVimEvaluator*)u{
    XVimSwapCharsEvaluator *eval = [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_LOWER] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator*)U{
    XVimSwapCharsEvaluator *eval = [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_UPPER] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator*)C_u{
    [self.currentView scrollHalfPageBackward:self.numericArg];
    return self;
}

- (XVimEvaluator*)v{
    XVimView *xview = self.currentView;

    if (xview.selectionMode == XVIM_VISUAL_CHARACTER) {
        return [self ESC];
    }
    xview.selectionMode = XVIM_VISUAL_CHARACTER;
    return self;
}

- (XVimEvaluator*)V{
    XVimView *xview = self.currentView;

    if (xview.selectionMode == XVIM_VISUAL_LINE) {
        return  [self ESC];
    }
    xview.selectionMode = XVIM_VISUAL_LINE;
    return self;
}

- (XVimEvaluator*)C_v{
    XVimView *xview = self.currentView;

    if (xview.selectionMode == XVIM_VISUAL_BLOCK) {
        return  [self ESC];
    }
    xview.selectionMode = XVIM_VISUAL_BLOCK;
    return self;
}

- (XVimEvaluator*)x{
    return [self d];
}

- (XVimEvaluator*)X{
    XVimView *xview = self.currentView;

    if (!xview.inBlockMode) {
        xview.selectionMode = XVIM_VISUAL_LINE;
    }
    return [self d];
}

- (XVimEvaluator*)y{
    [self.currentView doYank:nil];
    return nil;
}

- (XVimEvaluator*)Y{
    XVimView *xview = self.currentView;

    if (!xview.inBlockMode) {
        xview.selectionMode = XVIM_VISUAL_LINE;
    }
    return [self y];
}

- (XVimEvaluator*)DQUOTE{
    [self.argumentString appendString:@"\""];
    self.onChildCompleteHandler = @selector(onComplete_DQUOTE:);
    _waitForArgument = YES;
    return  [[[XVimRegisterEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_DQUOTE:(XVimRegisterEvaluator*)childEvaluator{
    NSString *xregister = childEvaluator.reg;
    if( [[[XVim instance] registerManager] isValidForYank:xregister] ){
        self.yankRegister = xregister;
        [self.argumentString appendString:xregister];
        self.onChildCompleteHandler = @selector(onChildComplete:);
    }
    else{
        return [XVimEvaluator invalidEvaluator];
    }
    _waitForArgument = NO;
    return self;
}

/*
TODO: This block is from commit 42498.
      This is not merged. This is about percent register
- (XVimEvaluator*)DQUOTE:(XVimWindow*)window{
    XVimEvaluator* eval = [[XVimRegisterEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"\""]
																  parent:self
															  completion:^ XVimEvaluator* (NSString* rname, XVimEvaluatorContext *context)  
						   {
							   XVimRegister *xregister = [[XVim instance] findRegister:rname];
							   if (xregister.isReadOnly == NO || [xregister.displayName isEqualToString:@"%"] ){
								   [context setYankRegister:xregister];
								   [context appendArgument:rname];
								   return [self withNewContext:context];
							   }
							   
							   [[XVim instance] ringBell];
							   return nil;
						   }];
	return eval;
}
*/

- (XVimEvaluator*)EQUAL{
    XVimEqualEvaluator* eval = [[[XVimEqualEvaluator alloc] initWithWindow:self.window] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, [self numericArg])];
}

- (XVimEvaluator*)ESC{
    self.currentView.selectionMode = XVIM_VISUAL_NONE;
    return nil;
}

- (XVimEvaluator*)C_c{
    return [self ESC];
}

- (XVimEvaluator*)C_LSQUAREBRACKET{
    return [self ESC];
}

- (XVimEvaluator*)C_RSQUAREBRACKET{
    [self.window errorMessage:@"{Visual}CTRL-] not implemented yet" ringBell:NO];
    return self;
}

- (XVimEvaluator*)COLON{
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithWindow:self.window
                                                                firstLetter:@":'<,'>"
                                                                    history:[[XVim instance] exCommandHistory]
                                                                 completion:^ XVimEvaluator* (NSString* command, id* result)
                           {
                               XVimExCommand *excmd = [[XVim instance] excmd];
                               [excmd executeCommand:command inWindow:self.window];

                               self.currentView.selectionMode = XVIM_VISUAL_NONE;
                               return nil;
                           }
                                                                 onKeyPress:nil];
	
	return eval;
}

- (XVimEvaluator *)EXCLAMATION{
    [self.window errorMessage:@"{Visual}!{filter} not implemented yet" ringBell:NO];
    return self;
}

- (XVimEvaluator*)GREATERTHAN{
    XVimShiftEvaluator* eval = [[[XVimShiftEvaluator alloc] initWithWindow:self.window unshift:NO] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator*)LESSTHAN{
    XVimShiftEvaluator* eval = [[[XVimShiftEvaluator alloc] initWithWindow:self.window unshift:YES] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator*)executeSearch:(XVimWindow*)window firstLetter:(NSString*)firstLetter {
    /*1
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
																	 parent:self 
															   firstLetter:firstLetter
																   history:[[XVim instance] searchHistory]
																completion:^ XVimEvaluator* (NSString *command)
						   {
							   XVimSearch *searcher = [[XVim instance] searcher];
							   NSTextView *sourceView = [window sourceView];
							   NSRange found = [searcher executeSearch:command 
															   display:[command substringFromIndex:1]
																  from:[window insertionPoint] 
															  inWindow:window];
							   //Move cursor and show the found string
							   if (found.location != NSNotFound) {
                                   unichar firstChar = [command characterAtIndex:0];
                                   if (firstChar == '?'){
                                       _insertion = found.location;
                                   }else if (firstChar == '/'){
                                       _insertion = found.location + command.length - 1;
                                   }
                                   [self updateSelectionInWindow:window];
								   [sourceView scrollTo:[window insertionPoint]];
								   [sourceView showFindIndicatorForRange:found];
							   } else {
								   [window errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchDisplayString] ringBell:TRUE];
							   }
                               return self;
						   }
                                                                onKeyPress:^void(NSString *command)
                           {
                               XVimOptions *options = [[XVim instance] options];
                               if (options.incsearch){
                                   XVimSearch *searcher = [[XVim instance] searcher];
                                   NSTextView *sourceView = [window sourceView];
                                   NSRange found = [searcher executeSearch:command 
																   display:[command substringFromIndex:1]
																	  from:[window insertionPoint] 
																  inWindow:window];
                                   //Move cursor and show the found string
                                   if (found.location != NSNotFound) {
                                       // Update the selection while preserving the current insertion point
                                       // The insertion point will be finalized if we complete a search
                                       NSUInteger prevInsertion = _insertion;
                                       unichar firstChar = [command characterAtIndex:0];
                                       if (firstChar == '?'){
                                           _insertion = found.location;
                                       }else if (firstChar == '/'){
                                           _insertion = found.location + command.length - 1;
                                       }
                                       [self updateSelectionInWindow:window];
                                       _insertion = prevInsertion;
                                       
                                       [sourceView scrollTo:found.location];
                                       [sourceView showFindIndicatorForRange:found];
                                   }
                               }
                           }];
	return eval;
     */
    return [self ESC]; // Temprarily this feture is turned off
}

- (XVimEvaluator*)QUESTION{
	return [self executeSearch:self.window firstLetter:@"?"];
}

- (XVimEvaluator*)SLASH{
	return [self executeSearch:self.window firstLetter:@"/"];
}

- (XVimEvaluator*)TILDE{
    XVimSwapCharsEvaluator *eval = [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_CASE] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, [self numericArg])];
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    if(!XVim.instance.isRepeating){
        [self.currentView moveCursorWithMotion:motion];
        [self resetNumericArg];
    }
    [self.argumentString setString:@""];
    return self;
}

@end
