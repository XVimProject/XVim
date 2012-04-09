//
//  XVimMotionArgumentEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"

// This is base class of an evaluator which takes arguments to determing the motion such as 'f','F'.
// When the subclass fix the motion it must call motionFixedFrom:To: method.
@interface XVimMotionArgumentEvaluator : XVimEvaluator{
@private
    XVimMotionEvaluator* _motionEvaluator;
}
@property (readonly) NSUInteger repeat;

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(BOOL)type inWindow:(XVimWindow*)window;
- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window;
- (id)initWithMotionEvaluator:(XVimMotionEvaluator*)evaluator withRepeat:(NSUInteger)repeat;
@end
