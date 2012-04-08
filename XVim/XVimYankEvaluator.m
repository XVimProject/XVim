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

- (XVimEvaluator*)y:(id)arg{
    // 'yy' should obey the repeat specifier 
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    if (self.repeat < 1) 
        return nil;
    
    DVTSourceTextView* view = [self textView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
}

@end


@implementation XVimYankAction
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    DVTSourceTextView* view = [self textView];
    [view selectOperationTargetFrom:from To:to Type:type];
    [view copy:self];
    [view setSelectedRange:NSMakeRange(from, 0)];
    return nil;
}
@end