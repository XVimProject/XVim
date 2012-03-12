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
    NSUInteger max = [[view string] length];
    if (max > 0) 
        max--;
    NSRange begin = [view selectedRange];
    NSRange start;
    NSRange end;
    
    if (_repeat == 1 && begin.location == max) {
        // edge case:
        // if repeat is only one and we are at the end of a file at an empty line
        // delete the current line even though it's "behind us" (sort of)
        // this is vi behavior.
        [view moveToBeginningOfLine:self];
        start = [view selectedRange];
        if (NSEqualRanges(start, begin)) { // we didn't move at all (empty line)
            [view moveBackward:self];
            start = [view selectedRange];
            end = begin;
            return [self _motionFixedFrom:start.location To:end.location Type:LINEWISE];
        }
    }
    [view moveToBeginningOfLine:self];
    start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }

    end = [view selectedRange];

    [view setSelectedRange:begin];
    return [self _motionFixedFrom:start.location To:end.location Type:LINEWISE];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    NSTextView* view = [self textView];
    NSString* string = [view string];
    
    if( [string length] == 0 )
        return nil;
    
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }

    if( to != 0 && type == CHARACTERWISE_EXCLUSIVE){
        to--;
    }else if( type == LINEWISE ){
        if( [string length] == to && [string length] == from ){
            // edge case:
            // if repeat is only one and we are at the end of a file at an empty line
            // delete the current line even though it's "behind us" (sort of)
            // this is vi behavior.
            if( 0 != [string length] ){
                from--;
                [view setSelectedRange:NSMakeRange(from, 1)];
                [view cut:self];
                return nil;
            }
        }
        [view setSelectedRange:NSMakeRange(to,0)];
        if( !isNewLine([[view string] characterAtIndex:to])){
            to = [view nextNewline];
            if( NSNotFound == to ){
                to = [view string].length-1;
            }
        }
        NSRange r = [view selectedRange];
        [view setSelectedRange:NSMakeRange(from,0)];
        from = [view prevNewline];
        [view setSelectedRange:r];
        if( NSNotFound == from ){
            from = 0;
        }else{
            from++;
        }
    }

    [view setSelectedRangeWithBoundsCheck:from To:to];
    [view cut:self];
    if (_insertModeAtCompletion == TRUE) {
        // Go to insert 
        [self xvim].mode = MODE_INSERT;
        return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
    }
    return nil;
}

@end
