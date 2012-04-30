//
//  XVimZEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimZEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "Logger.h"

@implementation XVimZEvaluator

- (XVimEvaluator*)b:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)t:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)z:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)MINUS:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)DOT:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)CR:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

@end