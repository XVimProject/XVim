//
//  XVimYankEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimYankEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"

@implementation XVimYankEvaluator

- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)y:(id)arg{
    // 'yy' should obey the repeat specifier 
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    if (_repeat < 1) 
        return nil;
    
    NSTextView* view = [self textView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:_repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    NSTextView* view = [self textView];
    [self selectOperationTargetFrom:from To:to Type:type];
    [view copy:self];
    [view setSelectedRange:NSMakeRange(from, 0)];
    return nil;
}

@end
