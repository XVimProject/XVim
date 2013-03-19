//
//  XVimChildEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimArgumentEvaluator.h"

@implementation XVimArgumentEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context withWindow:(XVimWindow*)window{
	if (self = [super initWithContext:context withWindow:window]){
	}
	return self;
}

- (void)dealloc{
    [super dealloc];
}

- (void)drawRect:(NSRect)rect{
//	return [_parent drawRect:rect];
}


- (BOOL)shouldDrawInsertionPoint{
//	return [_parent shouldDrawInsertionPoint];
    return YES;
}

- (float)insertionPointHeightRatio{
 //   return [_parent insertionPointHeightRatio];
    return 1.0;
}

- (NSString*)modeString {
//	return [_parent modeString];
   return @"";
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other {
//	return [super isRelatedTo:other] || other == _parent;
    return YES;
}

- (XVimEvaluator*)defaultNextEvaluator{
 //   retur_parent withNewContext];
    return nil;
}

@end
