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

- (XVimEvaluator*)b{
    //TODO: Must deal numeric arg as linenumber
    //return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE];
    return nil;
}

- (XVimEvaluator*)t{
    //TODO: Must deal numeric arg as linenumber
    //return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE];
    return nil;
}

- (XVimEvaluator*)z{
    //TODO: Must deal numeric arg as linenumber
    //return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE];
    return nil;
}

- (XVimEvaluator*)MINUS{
    //TODO: Must deal numeric arg as linenumber
    //return [self commonMotion:@selector(scrollBottom:) Type:CHARACTERWISE_EXCLUSIVE];
    return nil;
}

- (XVimEvaluator*)DOT{
    //TODO: Must deal numeric arg as linenumber
    //return [self commonMotion:@selector(scrollCenter:) Type:CHARACTERWISE_EXCLUSIVE];
    return nil;
}

- (XVimEvaluator*)CR{
    //TODO: Must deal numeric arg as linenumber
    //return [self commonMotion:@selector(scrollTop:) Type:CHARACTERWISE_EXCLUSIVE];
    return nil;
}

@end