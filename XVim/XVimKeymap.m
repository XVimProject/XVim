//
//  XVimKeymap.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeymap.h"
#import "XVimKeyStroke.h"

@interface XVimKeymap() {
	__strong NSMutableDictionary *_dict;
}
@end

@implementation XVimKeymap
- (id)init
{
	self = [super init];
	if (self) {
		_dict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)mapKeyStroke:(XVimKeyStroke*)keyStroke to:(NSArray*)targetKeyStrokes
{
	[_dict setObject:targetKeyStrokes forKey:keyStroke];
}

- (NSArray*)lookupKeyStroke:(XVimKeyStroke*)keyStroke
{
	NSArray* ret = NULL;
	
	ret = ret ? ret : [_dict objectForKey:keyStroke];
	ret = ret ? ret : [_dict objectForKey:[keyStroke keyStrokeByStrippingModifiers]];
	ret = ret ? ret : [NSArray arrayWithObject:keyStroke];
	
	return ret;
}

@end
