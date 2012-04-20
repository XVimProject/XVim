//
//  XVimDeleteEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimDeleteEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVimWindow.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"
#import "DVTSourceTextView.h"

@interface XVimDeleteEvaluator() {
	BOOL _insertModeAtCompletion;
}
@end

@implementation XVimDeleteEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
	   operatorAction:(XVimOperatorAction*)operatorAction 
				  withParent:(XVimEvaluator*)parent
	  insertModeAtCompletion:(BOOL)insertModeAtCompletion
{
	if (self = [super initWithContext:context
					   operatorAction:operatorAction 
								  withParent:parent
				])
	{
		self->_insertModeAtCompletion = insertModeAtCompletion;
	}
	return self;
}

- (XVimEvaluator*)c:(XVimWindow*)window
{
    if( !_insertModeAtCompletion ){
        return nil;  // 'dc' does nothing
    }
    // 'cc' should obey the repeat specifier
    // '3cc' should delete/cut the current line and the 2 lines below it
    
    if ([self numericArg] < 1) 
        return nil;
    
    DVTSourceTextView* view = [window sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:[self numericArg]-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}

- (XVimEvaluator*)d:(XVimWindow*)window{
    if( _insertModeAtCompletion ){
        return nil;  // 'cd' does nothing
    }
    // 'dd' should obey the repeat specifier
    // '3dd' should delete/cut the current line and the 2 lines below it
    
    if ([self numericArg] < 1) 
        return nil;
        
    DVTSourceTextView* view = [window sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:[self numericArg]-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}



- (XVimEvaluator*)w:(XVimWindow*)window{
    if( _insertModeAtCompletion ){ 
        // cw is special case of word motion
        XVimWordInfo info;
        NSUInteger from = [[window sourceView] selectedRange].location;
        NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:(XVimWordInfo*)&info];
        if( info.isFirstWordInALine ){
            return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE inWindow:window];
        }else{
            if( info.lastEndOfWord != NSNotFound){
                return [self _motionFixedFrom:from To:info.lastEndOfWord Type:CHARACTERWISE_INCLUSIVE inWindow:window];   
            }else{
                return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window]; 
            }
        }
    }else{
        return [super w:window];
    }
}

- (XVimEvaluator*)W:(XVimWindow*)window{
    if( _insertModeAtCompletion ){ 
        // cw is special case of word motion
        XVimWordInfo info;
        NSUInteger from = [[window sourceView] selectedRange].location;
        NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:BIGWORD info:(XVimWordInfo*)&info];
        if( info.isFirstWordInALine ){
            return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE inWindow:window];
        }else{
            if( info.lastEndOfWord != NSNotFound){
                return [self _motionFixedFrom:from To:info.lastEndOfWord Type:CHARACTERWISE_INCLUSIVE inWindow:window];   
            }else{
                return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window]; 
            }
        }
    }else{
        return [super W:window];
    }
}

- (XVimEvaluator*)j:(XVimWindow*)window{
    DVTSourceTextView *view = [window sourceView];
    NSUInteger from = [view selectedRange].location;
    NSUInteger headOfLine = [view headOfLine:from];
    if (headOfLine != NSNotFound){
        from = headOfLine;
    }

    NSUInteger to = from;
    NSUInteger start = headOfLine == NSNotFound ? 1 : 0;
    for (NSUInteger i = start; i < [self numericArg]; ++i){
        to = [view nextNewLine:to];
    }

    NSUInteger endOfLine = [view endOfLine:++to];
    if (endOfLine != NSNotFound){
        to = endOfLine;
    }

    MOTION_TYPE motion;
    if (_insertModeAtCompletion) {
        if ([view isBlankLine:to]) {
            motion = CHARACTERWISE_EXCLUSIVE;
        }else{
            motion = CHARACTERWISE_INCLUSIVE;
        }
    }else{
        motion = LINEWISE;   
    }

    return [self _motionFixedFrom:from To:to Type:motion inWindow:window];
}

- (XVimEvaluator*)k:(XVimWindow*)window{
    DVTSourceTextView *view = [window sourceView];
    NSUInteger to = [view selectedRange].location;
    NSUInteger endOfLine = [view endOfLine:to];
    if (endOfLine != NSNotFound){
        to = endOfLine;
    }

    NSUInteger from = to;
    for (NSUInteger i = 0; i < [self numericArg]; ++i){
        from = [view prevNewLine:from];
    }

    NSUInteger headOfLine = [view headOfLine:from];
    if (headOfLine != NSNotFound) {
        from = headOfLine;
    }

    MOTION_TYPE motion;
    if (_insertModeAtCompletion) {
        if ([view isBlankLine:to]) {
            motion = CHARACTERWISE_EXCLUSIVE;
        }else{
            motion = CHARACTERWISE_INCLUSIVE;
        }
    }else{
        motion = LINEWISE;   
    }

    return [self _motionFixedFrom:from To:to Type:motion inWindow:window];
}


@end

@interface XVimDeleteAction() {
	__weak XVimRegister* _yankRegister;
	BOOL _insertModeAtCompletion;
}
@end

@implementation XVimDeleteAction
- (id)initWithYankRegister:(XVimRegister*)xregister
	insertModeAtCompletion:(BOOL)insertModeAtCompletion
{
	if (self = [super init])
	{
		_insertModeAtCompletion = insertModeAtCompletion;
		_yankRegister = xregister;
	}
	return self;
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    DVTSourceTextView* view = [window sourceView];
    
    BOOL eof = [view isEOF:to];
    BOOL eol = [view isEOL:to];
    BOOL blank = [view isBlankLine:to];
    BOOL last = [view isLastCharacter:to];
    BOOL exclusive = type == CHARACTERWISE_EXCLUSIVE;
    TRACE_LOG(@"from: %d to: %d eof: %d eol: %d", from, to, eof, eol);
    if(from == to && (((eol || last) && exclusive) || eof)){
        // edge case:
        // if repeat is only one and we are at the end of a file at an empty line
        // delete the current line even though it's "behind us" (sort of)
        // this is vi behavior.
        [view setSelectedRange:NSMakeRange(eof && blank ? from - 1 : from, 1)];
        [view del:self intoYankRegister:_yankRegister];
        return nil;
    }
    
    [view selectOperationTargetFrom:from To:to Type:type];
    [view del:self intoYankRegister:_yankRegister];
    
    if (_insertModeAtCompletion == TRUE) {
        // Do not repeat the insert, that is how vim works so for
        // example 'c3wWord<ESC>' results in Word not WordWordWord
        if( type == LINEWISE ){
            // 'cc' deletes the lines but need to keep the last newline.
            // So insertNewline as 'O' does before entering insert mode
            if( [view _currentLineNumber] == 1 ){    // _currentLineNumber is implemented in DVTSourceTextView
                [view moveToBeginningOfLine:self];
                [view insertNewline:self];
                [view moveUp:self];
            }
            else {
                [view moveUp:self];
                [view moveToEndOfLine:self];
                [view insertNewline:self];
            }
        }
		else {
			[view setSelectedRangeWithBoundsCheck:from To:from];
		}
        return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]];
    }
    return nil;
}

@end