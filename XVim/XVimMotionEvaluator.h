//
//  XVimMotionEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimNumericEvaluator.h"
#import "XVimMotion.H"

// This evaluator handles motions.
// Make subclass of this to implement operation on which takes motions as argument (deletion,yank...and so on.)

@interface XVimMotionEvaluator : XVimNumericEvaluator

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type;

// Override this method to implement operations on motions.
-(XVimEvaluator*)motionFixed:(XVimMotion*)motion;
- (XVimEvaluator*)_motionFixed:(XVimMotion*)motion;
@end

