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
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimKeymapProvider.h"

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

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)a:(XVimWindow*)window {
	XVimEvaluator* eval = [[XVimTextObjectEvaluator alloc] initWithOperatorAction:_operatorAction repeat:_repeat inclusive:YES];
	return eval;
}

- (XVimEvaluator*)i:(XVimWindow*)window {
	XVimEvaluator* eval = [[XVimTextObjectEvaluator alloc] initWithOperatorAction:_operatorAction repeat:_repeat inclusive:NO];
	return eval;
}

- (XVimEvaluator*)w:(XVimWindow*)window{
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:(XVimWordInfo*)&info];
    if( info.isFirstWordInALine ){
        return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE inWindow:window];
    }else{
        return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
    }
}

- (XVimEvaluator*)W:(XVimWindow*)window{
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:BIGWORD info:(XVimWordInfo*)&info];
    if( info.isFirstWordInALine ){
        return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE inWindow:window];
    }else{
        return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
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

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
	return [self->_operatorAction motionFixedFrom:from To:to Type:type inWindow:window];
}

@end
