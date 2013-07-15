//
//  XVimNormalEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"
#import "XVimRegister.h"

// This evaluates events in Normal (COMMAND) mode
// This is the root evaluator.
// Every command and mode transition starts from this object.
// If XVimMotionEvaluator returns valid range object
// move the cusor to the position
@interface XVimNormalEvaluator : XVimMotionEvaluator
@end