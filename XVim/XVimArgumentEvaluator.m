//
//  XVimChildEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimArgumentEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"

@implementation XVimArgumentEvaluator
@synthesize keyStroke = _keyStroke;

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    self.keyStroke = keyStroke;
    return [self onArgumentProvided:keyStroke];
}

- (XVimEvaluator*)onArgumentProvided:(XVimKeyStroke*)key{
    return nil;
}

- (void)dealloc{
    self.keyStroke = nil;
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
