//
//  XVimNumericEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimNumericEvaluator.h"
#import "XVimKeyStroke.h"
#import "NSString+VimHelper.h"

@implementation XVimNumericEvaluator

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    
    if (keyStroke.isNumeric) {
        unichar     buf[4] = { 'N', 'U', 'M', keyStroke.character };
        NSUInteger  digit  = buf[3] - '0';

        if (self.numericMode || digit) {
            NSUInteger n = self.numericMode ?  self.numericArg : 0;

            self.numericMode = YES;
            if (n <= NSUIntegerMax / 10) {
                self.numericArg = 10 * n + digit;
                CFStringAppendCharacters((__bridge CFMutableStringRef)self.argumentString, buf, 4);
            }
            return self;
        }
    }
    
    return [super eval:keyStroke];
}

- (void)resetNumericArg{
    [super resetNumericArg];
    self.numericMode = NO;
}

@end
