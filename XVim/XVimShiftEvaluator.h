//
//  XVimShiftEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"

@interface XVimShiftEvaluator : XVimMotionEvaluator{
    NSUInteger _repeat;
}
@property BOOL unshift;
- (id) initWithRepeat:(NSUInteger)repeat;
@end
