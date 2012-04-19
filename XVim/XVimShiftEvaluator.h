//
//  XVimShiftEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimOperatorEvaluator.h"
#import "XVimOperatorAction.h"

@interface XVimShiftAction : XVimOperatorAction
- (id)initWithUnshift:(BOOL)unshift;
@property (readonly) BOOL unshift;
@end

@interface XVimShiftEvaluator : XVimOperatorEvaluator
- (id)initWithOperatorAction:(XVimShiftAction*)action 
				  withParent:(XVimEvaluator*)parent
				  numericArg:(NSUInteger)numericArg;
@end