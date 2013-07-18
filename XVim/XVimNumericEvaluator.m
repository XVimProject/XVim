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

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    NSString* keyStr = [keyStroke toSelectorString];
	
    
    if (keyStroke.isNumeric) {
        if (self.numericMode) {
            NSString* numStr = [keyStr substringFromIndex:3];
            NSUInteger n = (NSUInteger)[numStr integerValue]; 
			NSUInteger newHead = self.numericArg;
            // prevent integer overflow
            if(newHead <= floor((NSUIntegerMax - n) / 10)){
                newHead*=10; 
                newHead+=n;
                self.numericArg = newHead;
                [self.argumentString appendString:numStr];
            }
            return self;
        }
        else{
            if( [keyStr isEqualToString:@"NUM0"] ){
                // Nothing to do
                // Maybe handled by XVimNormalEvaluator
            }else{
                NSString* numStr = [keyStr substringFromIndex:3];
                NSUInteger n = (NSUInteger)[numStr integerValue]; 
				self.numericArg = n;
				[self.argumentString appendString:numStr];
                self.numericMode = YES;
                return self;
            }
        }
    }
    
    return [super eval:keyStroke];
}

- (void)resetNumericArg{
    [super resetNumericArg];
    self.numericMode = NO;
}

@end
