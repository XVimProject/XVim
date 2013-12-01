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
    [self.currentView scrollBottom:([self numericMode]?[self numericArg]:0) firstNonblank:NO];
    return nil;
}

- (XVimEvaluator*)t{
    [self.currentView scrollTop:([self numericMode]?[self numericArg]:0) firstNonblank:NO];
    return nil;
}

- (XVimEvaluator*)z{
    [self.currentView scrollCenter:([self numericMode]?[self numericArg]:0) firstNonblank:NO];
    return nil;
}

- (XVimEvaluator*)MINUS{
    [self.currentView scrollBottom:([self numericMode]?[self numericArg]:0) firstNonblank:YES];
    return nil;
}

- (XVimEvaluator*)DOT{
    [self.currentView scrollCenter:([self numericMode]?[self numericArg]:0) firstNonblank:YES];
    return nil;
}

- (XVimEvaluator*)CR{
    [self.currentView scrollTop:([self numericMode]?[self numericArg]:0) firstNonblank:YES];
    return nil;
}

@end