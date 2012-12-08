//
//  XVimChildEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimArgumentEvaluator.h"

@implementation XVimArgumentEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context withWindow:(XVimWindow*)window withParent:(XVimEvaluator*)parent{
	if (self = [super initWithContext:context withWindow:window]){
		_parent = parent;
	}
	return self;
}

- (void)drawRect:(NSRect)rect{
	return [_parent drawRect:rect];
}

- (BOOL)shouldDrawInsertionPoint{
	return [_parent shouldDrawInsertionPoint];
}

- (float)insertionPointHeightRatio{
    return [_parent insertionPointHeightRatio];
}

- (NSString*)modeString {
	return [_parent modeString];
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other {
	return [super isRelatedTo:other] || other == _parent;
}

- (XVimEvaluator*)defaultNextEvaluator{
    return [_parent withNewContext];
}

@end
