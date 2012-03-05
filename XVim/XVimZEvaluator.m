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

- (XVimEvaluator*)b:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)t:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)z:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)MINUS:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)DOT:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)CR:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE];
}

@end