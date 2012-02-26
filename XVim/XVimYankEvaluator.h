//
//  XVimYankEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"

@interface XVimYankEvaluator : XVimTextObjectEvaluator{
@private
    NSUInteger _repeat;
}
- (id)initWithRepeat:(NSUInteger)repeat;
@end




// FIXME: Temprarily place these evaluator here
//        Make file for these evaluators

// Evaluates 'g' command
@interface XVimgEvaluator : XVimTextObjectEvaluator{
}
@end
// Evaluates 'r' command
@interface XVimrEvaluator : XVimTextObjectEvaluator{
}
@end
