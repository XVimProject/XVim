//
//  XVimShiftEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimOperatorEvaluator.h"



@interface XVimShiftEvaluator : XVimOperatorEvaluator
- (id)initWithWindow:(XVimWindow*)window unshift:(BOOL)unshift;
@end
