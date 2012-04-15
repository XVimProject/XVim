//
//  XVimShiftEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimOperatorEvaluator.h"
#import "XVimOperatorAction.h"

@interface XVimShiftEvaluator : XVimOperatorEvaluator
- (id)initWithOperatorAction:(XVimOperatorAction*)action 
				  withParent:(XVimEvaluator*)parent
					  repeat:(NSUInteger)repeat 
					 unshift:(BOOL)unshift;
@end

@interface XVimShiftAction : XVimOperatorAction
- (id)initWithUnshift:(BOOL)unshift;
@end