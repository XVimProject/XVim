//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 8/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimOperatorAction.h"
#import "XVim.h"

@implementation XVimOperatorAction
@synthesize xvim = _xvim;

- (DVTSourceTextView*)textView
{
	return [self.xvim sourceView];
}

- (id)initWithXVim:(XVim*)xvim
{
	if (self = [super init])
	{
		self->_xvim = xvim;
	}
	return self;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type
{
	return nil; // No-op
}

@end
