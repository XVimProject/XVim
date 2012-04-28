//
//  XVimEvaluatorContext.m
//  XVim
//
//  Created by Tomas Lundell on 19/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluatorContext.h"

@interface XVimEvaluatorContext() {
	NSUInteger _numericArgTail;
	NSNumber *_numericArgHead;
	__weak XVimRegister *_yankRegister;
	NSString *_argumentString;
}
@end


@implementation XVimEvaluatorContext

- (id)init
{
	if (self = [super init])
	{
		_numericArgTail = 1;
		_numericArgHead = nil;
		_yankRegister = nil;
		_argumentString = @"";
	}
	return self;
}

+ (XVimEvaluatorContext*)contextWithNumericArg:(NSUInteger)numericArg
{
	XVimEvaluatorContext *instance = [[XVimEvaluatorContext alloc] init];
	instance->_numericArgTail = numericArg;
	return instance;
}

+ (XVimEvaluatorContext*)contextWithArgument:(NSString*)argument
{
	XVimEvaluatorContext *instance = [[XVimEvaluatorContext alloc] init];
	instance->_argumentString = [argument copy];
	return instance;
}

- (XVimRegister*)yankRegister
{
	return _yankRegister;
}

- (XVimEvaluatorContext*)setYankRegister:(XVimRegister*)yankRegister
{
	_yankRegister = yankRegister;
	return self;
}

- (NSUInteger)numericArg
{
	return _numericArgTail * (_numericArgHead ? [_numericArgHead unsignedIntegerValue] : 1);
}

- (void)pushEmptyNumericArgHead
{
	_numericArgTail = [self numericArg];
	_numericArgHead = nil;
}

- (void)setNumericArgHead:(NSUInteger)numericArg
{
	_numericArgHead = [NSNumber numberWithUnsignedInteger:numericArg];
}

- (NSNumber*)numericArgHead
{
	return _numericArgHead;
}

- (NSString*)argumentString
{
	return _argumentString;
}

- (XVimEvaluatorContext*)setArgumentString:(NSString*)argument
{
	_argumentString = [argument copy];
	return self;
}

- (XVimEvaluatorContext*)appendArgument:(NSString*)argument
{
	_argumentString = [_argumentString stringByAppendingString:argument];
	return self;
}

- (XVimEvaluatorContext*)copy
{
	XVimEvaluatorContext *instance = [[XVimEvaluatorContext alloc] init];
	instance->_argumentString = [self->_argumentString copy];
	instance->_numericArgTail = [self numericArg];
	instance->_numericArgHead = nil;
	instance->_yankRegister = self->_yankRegister;
	
	return instance;
}

@end