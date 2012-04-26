//
//  XVimMotionEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimNumericEvaluator.h"
#import "XVimMotionType.h"

// This evaluator handles motions.
// The simplest one is just "w" which will generate
// motion which represents current insertion point
// to the begining of next word.
// When motion is generated motionFixedFrom:To:Type: method is called.
// Make subclass of this to implement operation on which takes motions as argument (deletion,yank...and so on.)

@interface XVimMotionEvaluator : XVimNumericEvaluator 

- (XVimEvaluator*)h:(XVimWindow*)window;

// Override this method to implement operations on motions.
// There could be from < to (This means backwards motion)
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window;

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window;

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window;
@end

