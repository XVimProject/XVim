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
    [self.sourceView xvim_scrollBottom:([self numericMode]?[self numericArg]:0) firstNonblank:NO];
    return nil;
}

- (XVimEvaluator*)c{
    [NSApp sendAction:@selector(fold:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)C{
    // Xcode doesn't have a zC type feature so default to zc
    return [self c];
}

- (XVimEvaluator*)m{
    // Xcode doesn't have a zm type feature so default to zM
    return [self M];
}

- (XVimEvaluator*)M{
    [NSApp sendAction:@selector(foldAllComments:) to:nil from:self];
    [NSApp sendAction:@selector(foldAllMethods:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)o{
    [NSApp sendAction:@selector(unfold:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)O{
    // Xcode doesn't have a zO type feature so default to zo
    return [self o];
}

- (XVimEvaluator*)r{
    // Xcode doesn't have a zr type feature so default to zR
    return [self R];
}

- (XVimEvaluator*)R{
    [NSApp sendAction:@selector(unfoldAll:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)t{
    [self.sourceView xvim_scrollTop:([self numericMode]?[self numericArg]:0) firstNonblank:NO];
    return nil;
}

- (XVimEvaluator*)z{
    [self.sourceView xvim_scrollCenter:([self numericMode]?[self numericArg]:0) firstNonblank:NO];
    return nil;
}

- (XVimEvaluator*)MINUS{
    [self.sourceView xvim_scrollBottom:([self numericMode]?[self numericArg]:0) firstNonblank:YES];
    return nil;
}

- (XVimEvaluator*)DOT{
    [self.sourceView xvim_scrollCenter:([self numericMode]?[self numericArg]:0) firstNonblank:YES];
    return nil;
}

- (XVimEvaluator*)CR{
    [self.sourceView xvim_scrollTop:([self numericMode]?[self numericArg]:0) firstNonblank:YES];
    return nil;
}

@end
