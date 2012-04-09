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
@synthesize repeat;

- (id)initWithMotionEvaluator:(XVimMotionEvaluator*)evaluator withRepeat:(NSUInteger)rep{
    self = [super init];
    if( self ){
        repeat = rep;
        _motionEvaluator = [evaluator retain];
    }
    return self;
}

- (void)dealloc{
    [_motionEvaluator release];
    [super dealloc];
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
@end
