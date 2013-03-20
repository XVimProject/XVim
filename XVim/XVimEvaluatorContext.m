//
//  XVimEvaluatorContext.m
//  XVim
//
//  Created by Tomas Lundell on 19/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluatorContext.h"
/*
@implementation XVimEvaluatorContext
@synthesize numericArg = _numericArg;
@synthesize yankRegister = _yankRegister;
@synthesize argumentString = _argumentString;

- (id)init{
	if (self = [super init]) {
        self.numericArg = 1;
        self.yankRegister = nil;
        self.argumentString = [[NSMutableString alloc] init];
	}
	return self;
}

- (void)dealloc{
    self.argumentString = nil;
    [super dealloc];
}

+ (XVimEvaluatorContext*)contextWithNumericArg:(NSUInteger)numericArg{
	XVimEvaluatorContext *instance = [[[XVimEvaluatorContext alloc] init] autorelease];
    instance.numericArg = numericArg;
	return instance;
}

+ (XVimEvaluatorContext*)contextWithArgument:(NSString*)argument {
	XVimEvaluatorContext *instance = [[[XVimEvaluatorContext alloc] init] autorelease];
    [instance.argumentString appendString:argument];
	return instance;
}


- (XVimEvaluatorContext*)copy {
	XVimEvaluatorContext *instance = [[XVimEvaluatorContext alloc] init];
    instance.argumentString = [[self.argumentString copy] autorelease];
    instance.numericArg = self.numericArg;
    instance.yankRegister = self.yankRegister;
	return instance;
}

@end
*/