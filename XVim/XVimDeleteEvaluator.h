//
//  XVimDeleteEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//


#import "XVimOperatorEvaluator.h"
#import "XVimOperatorAction.h"

// Handles input after 'd' or 'c'
@interface XVimDeleteEvaluator : XVimOperatorEvaluator
- (id)initWithOperatorAction:(XVimOperatorAction*)operatorAction repeat:(NSUInteger)repeat insertModeAtCompletion:(BOOL)insertModeAtCompletion;
@end

@interface XVimDeleteAction : XVimOperatorAction
- (id)initWithInsertModeAtCompletion:(BOOL)insertModeAtCompletion;
@end