//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimOperatorEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimOperatorAction.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimKeymapProvider.h"

@interface XVimOperatorEvaluator() {
	XVimOperatorAction *_operatorAction;
	XVimEvaluator *_parent;
}
@end

@implementation XVimOperatorEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
	   operatorAction:(XVimOperatorAction*) action 
				  withParent:(XVimEvaluator*)parent
{
	if (self = [super initWithContext:context])
	{
		self->_operatorAction = action;
		self->_parent = parent;
	}
	return self;
}

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return [_parent insertionPointInWindow:window];
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
	return [_parent drawRect:rect inWindow:window];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return [_parent shouldDrawInsertionPointInWindow:window];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio
{
	return [_parent drawInsertionPointInRect:rect color:color inWindow:window heightRatio:.5];
}

- (NSString*)modeString
{
	return [_parent modeString];
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other
{
	return [super isRelatedTo:other] || other == _parent;
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window{
    return [_parent withNewContext];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)a:(XVimWindow*)window {
	XVimEvaluator* eval = [[XVimTextObjectEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"a"]
															operatorAction:_operatorAction 
																	   withParent:_parent
																		inclusive:YES];
	return eval;
}

- (XVimEvaluator*)b:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsBackward:from count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)B:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsBackward:from count:[self numericArg] option:BIGWORD];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}


- (XVimEvaluator*)i:(XVimWindow*)window {
	XVimEvaluator* eval = [[XVimTextObjectEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"i"]
															operatorAction:_operatorAction 
																	   withParent:_parent
																		inclusive:NO];
	return eval;
}

- (XVimEvaluator*)w:(XVimWindow*)window{
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:(XVimWordInfo*)&info];
    if (info.isFirstWordInALine && info.lastEndOfLine != NSNotFound) {
        return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE inWindow:window];
    } else {
        return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
    }
}

- (XVimEvaluator*)W:(XVimWindow*)window{
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:BIGWORD info:(XVimWordInfo*)&info];
    if (info.isFirstWordInALine && info.lastEndOfLine != NSNotFound) {
        return [self _motionFixedFrom:from To:info.lastEndOfLine Type:CHARACTERWISE_INCLUSIVE inWindow:window];
    } else {
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
