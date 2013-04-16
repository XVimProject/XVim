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
    [self.sourceView scrollBottom:([self numericMode]?[self numericArg]:0) firstNonBlank:NO];
    return nil;
}

- (XVimEvaluator*)t{
    [self.sourceView scrollTop:([self numericMode]?[self numericArg]:0) firstNonBlank:NO];
    return nil;
}

- (XVimEvaluator*)z{
    [self.sourceView scrollCenter:([self numericMode]?[self numericArg]:0) firstNonBlank:NO];
    return nil;
}

- (XVimEvaluator*)MINUS{
    [self.sourceView scrollBottom:([self numericMode]?[self numericArg]:0) firstNonBlank:YES];
    return nil;
}

- (XVimEvaluator*)DOT{
    [self.sourceView scrollCenter:([self numericMode]?[self numericArg]:0) firstNonBlank:YES];
    return nil;
}

- (XVimEvaluator*)CR{
    [self.sourceView scrollTop:([self numericMode]?[self numericArg]:0) firstNonBlank:YES];
    return nil;
}

@end