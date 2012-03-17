//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSTextView+VimMotion.h"
#import "XVimOperatorEvaluator.h"

@implementation XVimOperatorEvaluator

- (XVimEvaluator*)w:(id)arg{
    XVimWordInfo info;
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:(XVimWordInfo*)&info];
    if( info.isFirstWordInALine ){
        return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE];
    }else{
        return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
    }
}

- (XVimEvaluator*)W:(id)arg{
    XVimWordInfo info;
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] wordsForward:from count:[self numericArg] option:BIGWORD info:(XVimWordInfo*)&info];
    if( info.isFirstWordInALine ){
        return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE];
    }else{
        return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
    }
}


@end
