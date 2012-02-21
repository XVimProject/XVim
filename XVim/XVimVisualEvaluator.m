//
//  XVimVisualEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimVisualEvaluator.h"
#import "XVim.h"

@implementation XVimVisualEvaluator 
@synthesize lineSelection;

- (id)initWithOriginalSelectedRange:(NSRange)selection{
    self = [super init];
    if (self) {
        _origin = selection.location;
    }
    return self;
}

- (XVimEvaluator*)defaultNextEvaluator{
    return self;
}

- (XVimEvaluator*)d:(id)arg{
    NSTextView* view = [self textView];
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)y:(id)arg{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    [view copy:self];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}
- (XVimEvaluator*)w:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveWordForwardAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)W:(id)arg{
    
    return self;
}

- (XVimEvaluator*)b:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveWordBackwardAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)B:(id)arg{
    return self;
}

- (XVimEvaluator*)C_d:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view pageDownAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
    
}

- (XVimEvaluator*)C_u:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view pageUpAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)NUM0:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToBeginningOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)DOLLAR:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToEndOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)k:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUpAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)j:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDownAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)l:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveRightAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)h:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveLeftAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}


- (XVimEvaluator*)PLUS:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDownAndModifySelection:self];
        [view moveToBeginningOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)MINUS:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUpAndModifySelection:self];
        [view moveToBeginningOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)ESC:(id)arg{
    [self xvim].mode = MODE_NORMAL;
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [[self textView] setSelectedRange:r];
    return nil;
}

- (XVimEvaluator*)GREATERTHAN:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    [self resetNumericArg];
    [self xvim].mode = MODE_NORMAL;
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    [self resetNumericArg];
    [self xvim].mode = MODE_NORMAL;
    return nil;
}
@end

