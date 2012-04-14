//
//  XVimMotionArgumentEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMotionArgumentEvaluator.h"
#import "XVimKeyStroke.h"


// This evaluator is base class of an evaluator which takes argument to fix the motion
// e.g. 'f','F'
@implementation XVimMotionArgumentEvaluator

- (id)initWithMotionEvaluator:(XVimMotionEvaluator*)evaluator {
    self = [super init];
    if( self ){
        _motionEvaluator = [evaluator retain];
    }
    return self;
}

- (void)dealloc{
    [_motionEvaluator release];
    [super dealloc];
}

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return [_motionEvaluator insertionPointInWindow:window];
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
	return [_motionEvaluator drawRect:rect inWindow:window];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return [_motionEvaluator shouldDrawInsertionPointInWindow:window];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio
{
	return [_motionEvaluator drawInsertionPointInRect:rect color:color inWindow:window heightRatio:heightRatio];
}

- (NSString*)modeString
{
	return [_motionEvaluator modeString];
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window{
    return _motionEvaluator;
}

-(XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    if( nil != _motionEvaluator ){
        return [_motionEvaluator motionFixedFrom:from To:to Type:type inWindow:window];
    }
    return nil;
}

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(BOOL)type inWindow:(XVimWindow*)window
{
    if( nil != _motionEvaluator ){
        return [_motionEvaluator commonMotion:motion Type:type inWindow:window];
    }
    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister
{
    if (xregister.isRepeat){
        if (xregister.nonNumericKeyCount == 1){
            if([keyStroke classResponds:[XVimMotionArgumentEvaluator class]] || keyStroke.isNumeric){
                return REGISTER_APPEND;
            }
        }
        
        return REGISTER_IGNORE;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

- (NSUInteger)numericArg
{
	return [_motionEvaluator numericArg] * [super numericArg];
}
@end
