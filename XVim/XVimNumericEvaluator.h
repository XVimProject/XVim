//
//  XVimNumericEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimEvaluator.h"

// This evaluator is waiting for number input.
@interface XVimNumericEvaluator : XVimEvaluator{
    NSUInteger _numericArg;
    BOOL _numericMode;
}
@property BOOL numericMode;
@property NSUInteger numericArg;
- (NSUInteger)numericArg;
- (void)resetNumericArg;
@end
