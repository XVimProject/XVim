//
//  XVimShiftEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimShiftEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"

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
        NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:_repeat-1 option:MOTION_OPTION_NONE];
        return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    //unshift
    if( unshift ){
        NSTextView* view = [self textView];
        NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:_repeat-1 option:MOTION_OPTION_NONE];
        return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
    }
    return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    DVTSourceTextView* view = (DVTSourceTextView*)[self textView];
    [self selectOperationTargetFrom:from To:to Type:type];
    if( unshift ){
        [view shiftLeft:self];
    }else{
        [view shiftRight:self];
    }
    [view setSelectedRange:NSMakeRange([view selectedRange].location, 0)];
    return nil;
}
@end
