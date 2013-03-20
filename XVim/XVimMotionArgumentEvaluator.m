//
//  XVimMotionArgumentEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMotionArgumentEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimMotionEvaluator.h"

// This evaluator is base class of an evaluator which takes argument to fix the motion
// e.g. 'f','F'
@implementation XVimMotionArgumentEvaluator

- (id)initWithWindow:(XVimWindow*)window{
	if (self = [super initWithWindow:window]) {
	}
	return self;
}

/*
- (XVimMotionEvaluator*)motionEvaluator {
	return (XVimMotionEvaluator*)_parent;
}
*/

-(XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    // TODO: support onChileComplete
    return nil;
}

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type{
    // TODO: support onChileComplete
    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister {
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
