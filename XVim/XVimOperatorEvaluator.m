//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"
#import "XVimOperatorEvaluator.h"
#import "XVimKeyStroke.h"
#import "Logger.h"

@implementation XVimOperatorEvaluator

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
	return keymaps[MODE_OPERATOR_PENDING];
}

- (NSRange)getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }
    
    DVTSourceTextView* view = [self textView];
    if( type == CHARACTERWISE_EXCLUSIVE ){
    }else if( type == CHARACTERWISE_INCLUSIVE ){
		to++;
    }else if( type == LINEWISE ){
        to = [view tailOfLine:to] + 1;
        NSUInteger head = [view headOfLine:from];
        if( NSNotFound != head ){
            from = head; 
        }
    }
	
	return NSMakeRange(from, to - from);
}
	

- (void)selectOperationTargetFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
	NSRange opRange = [self getOperationRangeFrom:from To:to Type:type];
	DVTSourceTextView* view = [self textView];
    [view setSelectedRangeWithBoundsCheck:opRange.location To:opRange.location + opRange.length];
}

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

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if([keyStroke instanceResponds:self] || keyStroke.isNumeric){
        TRACE_LOG(@"REGISTER_APPEND");
        return REGISTER_APPEND;
    }
    
    TRACE_LOG(@"REGISTER_IGNORE");
    return REGISTER_IGNORE;
}

@end
