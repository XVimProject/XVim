//
//  XVimSearchEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"

@interface XVimSearchLineEvaluator : XVimMotionArgumentEvaluator{
}
@property BOOL forward;
@end
