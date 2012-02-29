//
//  XVimGEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimGEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"

@implementation XVimGEvaluator
- (XVimEvaluator*)g:(id)arg{
    METHOD_TRACE_LOG();
    NSTextView* view = [self textView];
    return [self motionFixedFrom:[view selectedRange].location To:0];
}
@end