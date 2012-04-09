//
//  XVimLocalMarkEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/4/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"

// This evaluator is collecting a mark name as part of the 'm{mark-name-letter}' command
@interface XVimLocalMarkEvaluator : XVimEvaluator{
@private
    XVimMarkOperator _markOperator;
}
- (id)initWithMarkOperator:(XVimMarkOperator)markOperator;
@end
