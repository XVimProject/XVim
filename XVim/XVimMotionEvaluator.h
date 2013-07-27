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
@property (strong) XVimMotion* motion;

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type;

/**
 * The difference between motionFixed and _motionFixed:
 * _motionFixed is called internaly from its inherited classes.
 * After _motionFixed method does some common conversion to the motion or commmon operation
 * it calls motionFixed method with the converted motion.
 * So mainly you have to implement motionFixed method to delete/yanking or other operation with a motion.
 * If you want to implement new motion for a input you implement a selector for the input
 * and should call _motionFixed with the newly created motion.
 **/
// Override this method to implement operations on motions.
 -(XVimEvaluator*)motionFixed:(XVimMotion*)motion;

// Do not override this method
- (XVimEvaluator*)_motionFixed:(XVimMotion*)motion;


// These are only for surpress warning
- (XVimEvaluator*)b;
- (XVimEvaluator*)B;
@end

