//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"
#import "XVimOperatorEvaluator.h"
#import "XVimOperatorAction.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimKeyStroke.h"
#import "Logger.h"

@interface XVimOperatorEvaluator() {
	XVimOperatorAction *_operatorAction;
}
@end

@implementation XVimOperatorEvaluator
@synthesize repeat = _repeat;

- (id)initWithOperatorAction:(XVimOperatorAction*) action repeat:(NSUInteger)repeat
{
	if (self = [super init])
	{
		self->_operatorAction = action;
		self->_repeat = repeat;
	}
	return self;
}

- (id)initWithOperatorAction:(XVimOperatorAction*) action
{
	return [self initWithOperatorAction:action repeat:1];
}

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
	return keymaps[MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)a:(id)arg {
	XVimEvaluator* eval = [[XVimTextObjectEvaluator alloc] initWithOperatorAction:_operatorAction repeat:_repeat inclusive:YES];
	eval.xvim = self.xvim;
	return eval;
}

- (XVimEvaluator*)i:(id)arg {
	XVimEvaluator* eval = [[XVimTextObjectEvaluator alloc] initWithOperatorAction:_operatorAction repeat:_repeat inclusive:NO];
	eval.xvim = self.xvim;
	return eval;
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

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
	return [self->_operatorAction motionFixedFrom:from To:to Type:type];
}

@end
