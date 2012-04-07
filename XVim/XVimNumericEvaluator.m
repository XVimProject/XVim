//
//  XVimNumericEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimNumericEvaluator.h"
#import "XVimKeyStroke.h"

@implementation XVimNumericEvaluator
@synthesize numericMode,numericArg;
- (id)init
{
    self = [super init];
    if (self) {
        self.numericArg = 1;
        self.numericMode = NO;
    }
    return self;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke ofXVim:(XVim*)xvim{
    NSString* keyStr = [keyStroke toSelectorString];
    if( keyStroke.isNumeric ){
        if( self.numericMode ){
            NSString* numStr = [keyStr substringFromIndex:3];
            NSInteger n = [numStr integerValue]; 
            self.numericArg*=10; //FIXME: consider integer overflow
            self.numericArg+=n;
            return self;
        }
        else{
            if( [keyStr isEqualToString:@"NUM0"] ){
                // Nothing to do
                // Maybe handled by XVimNormalEvaluator
            }else{
                NSString* numStr = [keyStr substringFromIndex:3];
                NSInteger n = [numStr integerValue]; 
                self.numericArg=n;
                self.numericMode=YES;
                return self;
            }
        }
    }
    
    XVimEvaluator *nextEvaluator = [super eval:keyStroke ofXVim:xvim];
    [self resetNumericArg]; // Reset the numeric arg after evaluating an event
    return nextEvaluator;
}

- (void)resetNumericArg{
    self.numericArg = 1;
    self.numericMode = NO;
}
@end
