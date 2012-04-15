//
//  XVimSearchEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimMotionArgumentEvaluator.h"

@interface XVimSearchLineEvaluator : XVimMotionArgumentEvaluator
@property BOOL forward;
@property BOOL previous;
@end
