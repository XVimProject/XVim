//
//  XVimEqualEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"

@interface XVimEqualEvaluator : XVimMotionEvaluator{
@private
    NSUInteger _repeat;
}
- (id)initWithRepeat:(NSUInteger)repeat;
+ (XVimEvaluator*)indent:(XVimEvaluator*)evaluator;
@end
