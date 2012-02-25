//
//  XVimDeleteEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimDeleteEvaluator.h"
#import "XVim.h"

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
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }
    [view moveToEndOfLine:self];
    [view moveForward:self]; // include eol
    NSRange end = [view selectedRange];
    NSUInteger max = [[[self textView] string] length] - 1;
    [self setTextObject:NSMakeRange(start.location, end.location > max ? max-start.location: end.location-start.location)];
    // set cursor back to original position
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

-(XVimEvaluator*)textObjectFixed{
    NSTextView* view = [self textView];
    [view setSelectedRange:[self textObject]];
    [view cut:self];
    if (_insertModeAtCompletion == TRUE) {
        // Go to insert 
        [self xvim].mode = MODE_INSERT;
        return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
    }
    return nil;
}

@end
