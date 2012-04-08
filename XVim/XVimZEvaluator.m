//
//  XVimZEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimZEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimMotionEvaluator.h"
#import "Logger.h"

@implementation XVimZEvaluator

- (XVimEvaluator*)b:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)t:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)z:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)MINUS:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)DOT:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)CR:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

@end