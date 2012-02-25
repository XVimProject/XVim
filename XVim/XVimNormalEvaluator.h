//
//  XVimNormalEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"

// This evaluates events in Normal (COMMAND) mode
// This is the root evaluator.
// Every command and mode transition starts from this object.
// If XVimTextObjectEvaluator returns valid range object
// move the cusor to the position
@interface XVimNormalEvaluator : XVimTextObjectEvaluator
@end
