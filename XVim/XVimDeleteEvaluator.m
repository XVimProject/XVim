//
//  XVimDeleteEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimDeleteEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVim.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"
#import "DVTSourceTextView.h"

@interface XVimDeleteEvaluator() {
	BOOL _insertModeAtCompletion;
}
@end

@implementation XVimDeleteEvaluator

- (id)initWithOperatorAction:(XVimOperatorAction*)operatorAction repeat:(NSUInteger)repeat insertModeAtCompletion:(BOOL)insertModeAtCompletion
{
	if (self = [super initWithOperatorAction:operatorAction repeat:repeat])
	{
		self->_insertModeAtCompletion = insertModeAtCompletion;
	}
	return self;
}

- (XVimEvaluator*)c:(XVim*)xvim
{
    if( !_insertModeAtCompletion ){
        return nil;  // 'dc' does nothing
    }
    // 'cc' should obey the repeat specifier
    // '3cc' should delete/cut the current line and the 2 lines below it
    
    if (self.repeat < 1) 
        return nil;
    
    DVTSourceTextView* view = [xvim sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE XVim:xvim];
}

- (XVimEvaluator*)d:(XVim*)xvim{
    if( _insertModeAtCompletion ){
        return nil;  // 'cd' does nothing
    }
    // 'dd' should obey the repeat specifier
    // '3dd' should delete/cut the current line and the 2 lines below it
    
    if (self.repeat < 1) 
        return nil;
        
    DVTSourceTextView* view = [xvim sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE XVim:xvim];
}



- (XVimEvaluator*)w:(XVim*)xvim{
    if( _insertModeAtCompletion ){ 
        // cw is special case of word motion
        XVimWordInfo info;
        NSUInteger from = [[xvim sourceView] selectedRange].location;
        NSUInteger to = [[xvim sourceView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:(XVimWordInfo*)&info];
        if( info.isFirstWordInALine ){
            return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
        }else{
            if( info.lastEndOfWord != NSNotFound){
                return [self _motionFixedFrom:from To:info.lastEndOfWord Type:CHARACTERWISE_INCLUSIVE XVim:xvim];   
            }else{
                return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim]; 
            }
        }
    }else{
        return [super w:xvim];
    }
}

- (XVimEvaluator*)W:(XVim*)xvim{
    if( _insertModeAtCompletion ){ 
        // cw is special case of word motion
        XVimWordInfo info;
        NSUInteger from = [[xvim sourceView] selectedRange].location;
        NSUInteger to = [[xvim sourceView] wordsForward:from count:[self numericArg] option:BIGWORD info:(XVimWordInfo*)&info];
        if( info.isFirstWordInALine ){
            return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
        }else{
            if( info.lastEndOfWord != NSNotFound){
                return [self _motionFixedFrom:from To:info.lastEndOfWord Type:CHARACTERWISE_INCLUSIVE XVim:xvim];   
            }else{
                return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim]; 
            }
        }
    }else{
        return [super W:xvim];
    }
}

- (XVimEvaluator*)j:(XVim*)xvim{
    DVTSourceTextView *view = [xvim sourceView];
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

    return [self _motionFixedFrom:from To:to Type:motion XVim:xvim];
}

- (XVimEvaluator*)k:(XVim*)xvim{
    DVTSourceTextView *view = [xvim sourceView];
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

    return [self _motionFixedFrom:from To:to Type:motion XVim:xvim];
}


@end

@interface XVimDeleteAction() {
	BOOL _insertModeAtCompletion;
}
@end

@implementation XVimDeleteAction

- (id)initWithInsertModeAtCompletion:(BOOL)insertModeAtCompletion
{
	if (self = [super init])
	{
		self->_insertModeAtCompletion = insertModeAtCompletion;
	}
	return self;
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
    DVTSourceTextView* view = [xvim sourceView];
    NSString* string = [view string];
    
    if( [string length] != 0 && [string length] == to && [string length] == from){
        // edge case:
        // if repeat is only one and we are at the end of a file at an empty line
        // delete the current line even though it's "behind us" (sort of)
        // this is vi behavior.
        from--;
        [view setSelectedRange:NSMakeRange(from, 1)];
        [view cut:self];
        return nil;
    }
    
    [view selectOperationTargetFrom:from To:to Type:type];
    [view cut:self];
    
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
        return [[XVimInsertEvaluator alloc] initWithRepeat:1];
    }
    return nil;
}

@end