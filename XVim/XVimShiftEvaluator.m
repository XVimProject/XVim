//
//  XVimShiftEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimShiftEvaluator.h"

@implementation XVimShiftEvaluator
@synthesize unshift;

- (id) initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)GREATERTHAN:(id)arg{
    if( !unshift ){
        NSTextView* view = [self textView];
        [view shiftRight:self];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    //unshift
    if( unshift ){
        NSTextView* view = [self textView];
        [view shiftLeft:self];
    }
    return nil;
}
@end
