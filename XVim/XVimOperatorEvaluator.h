//
//  XVimOperatorEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMotionEvaluator.h"

// This is the base class for all the evaluators handling operations.
// This currently exists only to overriding 'w' operations.
// When 'w' is used with operator its motion is a little different.
// See ':help word' in Vim for the difference.

@class XVimOperatorAction;

@interface XVimOperatorEvaluator : XVimMotionEvaluator
- (id)initWithOperatorAction:(XVimOperatorAction*) action repeat:(NSUInteger)repeat;
- (id)initWithOperatorAction:(XVimOperatorAction*) action;

@property (nonatomic) NSUInteger repeat;

- (XVimEvaluator*)w:(XVimWindow*)window;
- (XVimEvaluator*)W:(XVimWindow*)window;
@end
