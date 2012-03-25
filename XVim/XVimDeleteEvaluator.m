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

@implementation XVimDeleteEvaluator

- (id)init
{
    return [self initWithRepeat:1 insertModeAtCompletion:FALSE];
}

- (id)initWithRepeat:(NSUInteger)repeat insertModeAtCompletion:(BOOL)insertModeAtCompletion {
    self = [super init];
    if (self) {
        _insertModeAtCompletion = insertModeAtCompletion;
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)d:(id)arg{
    // 'dd' should obey the repeat specifier
    // '3dd' should delete/cut the current line and the 2 lines below it
    
    if (_repeat < 1) 
        return nil;
        
    NSTextView* view = [self textView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:_repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
}



- (XVimEvaluator*)w:(id)arg{
    if( _insertModeAtCompletion ){ 
        // cw is special case of word motion
        XVimWordInfo info;
        NSUInteger from = [[self textView] selectedRange].location;
        NSUInteger to = [[self textView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:(XVimWordInfo*)&info];
        if( info.isFirstWordInALine ){
            return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE];
        }else{
            if( info.lastEndOfWord != NSNotFound){
                return [self _motionFixedFrom:from To:info.lastEndOfWord Type:CHARACTERWISE_INCLUSIVE];   
            }else{
                return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE]; 
            }
        }
    }else{
        return [super w:arg];
    }
}

- (XVimEvaluator*)W:(id)arg{
    if( _insertModeAtCompletion ){ 
        // cw is special case of word motion
        XVimWordInfo info;
        NSUInteger from = [[self textView] selectedRange].location;
        NSUInteger to = [[self textView] wordsForward:from count:[self numericArg] option:BIGWORD info:(XVimWordInfo*)&info];
        if( info.isFirstWordInALine ){
            return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE];
        }else{
            if( info.lastEndOfWord != NSNotFound){
                return [self _motionFixedFrom:from To:info.lastEndOfWord Type:CHARACTERWISE_INCLUSIVE];   
            }else{
                return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE]; 
            }
        }
    }else{
        return [super W:arg];
    }
}

- (XVimEvaluator*)j:(id)arg{
    NSTextView *view = [self textView];
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

    return [self _motionFixedFrom:from To:to Type:motion];
}

- (XVimEvaluator*)k:(id)arg{
    NSTextView *view = [self textView];
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

    return [self _motionFixedFrom:from To:to Type:motion];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    NSTextView* view = [self textView];
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
    
    [self selectOperationTargetFrom:from To:to Type:type];
    [view cut:self];
    
    if (_insertModeAtCompletion == TRUE) {
        // Do not repeat the insert, that is how vim works so for
        // example 'c3wWord<ESC>' results in Word not WordWordWord
        return [[XVimInsertEvaluator alloc] initWithRepeat:1 ofXVim:self.xvim];
    }
    return nil;
}

@end

