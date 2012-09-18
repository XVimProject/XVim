//
//  XVimChildEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimArgumentEvaluator.h"

@implementation XVimArgumentEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
			   parent:(XVimEvaluator*)parent
{
	if (self = [super initWithContext:context])
	{
		_parent = parent;
	}
	return self;
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
	return [_parent drawRect:rect inWindow:window];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return [_parent shouldDrawInsertionPointInWindow:window];
}

- (float)insertionPointHeightRatio{
    return [_parent insertionPointHeightRatio];
}

- (NSString*)modeString
{
	return [_parent modeString];
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other
{
	return [super isRelatedTo:other] || other == _parent;
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window
{
    return [_parent withNewContext];
}

@end
