//
//  XVimNumericEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimNumericEvaluator.h"
#import "XVimKeyStroke.h"

@interface XVimNumericEvaluator() {
    NSUInteger _numericArg;
    BOOL _numericMode;
}
- (void)resetNumericArg;
@end

@implementation XVimNumericEvaluator
- (id)init
{
    self = [super init];
    if (self) {
		[self resetNumericArg];
    }
    return self;
}

- (NSUInteger)numericArg
{
	return _numericArg;
}

- (BOOL)numericMode
{
	return _numericMode;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    NSString* keyStr = [keyStroke toSelectorString];
    if( keyStroke.isNumeric ){
        if( _numericMode ){
            NSString* numStr = [keyStr substringFromIndex:3];
            NSInteger n = [numStr integerValue]; 
            _numericArg*=10; //FIXME: consider integer overflow
            _numericArg+=n;
            return self;
        }
        else{
            if( [keyStr isEqualToString:@"NUM0"] ){
                // Nothing to do
                // Maybe handled by XVimNormalEvaluator
            }else{
                NSString* numStr = [keyStr substringFromIndex:3];
                NSInteger n = [numStr integerValue]; 
                _numericArg=n;
                _numericMode=YES;
                return self;
            }
        }
    }
    
    XVimEvaluator *nextEvaluator = [super eval:keyStroke inWindow:window];
    [self resetNumericArg]; // Reset the numeric arg after evaluating an event
    return nextEvaluator;
}

- (void)resetNumericArg{
    _numericArg = 1;
    _numericMode = NO;
}
@end
