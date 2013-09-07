//
//  XVimDeleteEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//


#import "XVimOperatorEvaluator.h"

// Handles input after 'd' or 'c'
@interface XVimDeleteEvaluator : XVimOperatorEvaluator
- (id)initWithWindow:(XVimWindow*)window insertModeAtCompletion:(BOOL)insertModeAtCompletion;
@end
