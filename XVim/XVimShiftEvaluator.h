//
//  XVimShiftEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"

@interface XVimShiftEvaluator : XVimTextObjectEvaluator{
    NSUInteger _repeat;
}
@property BOOL unshift;
- (id) initWithRepeat:(NSUInteger)repeat;
@end
