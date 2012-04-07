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

- (NSArray*)lookupKeyStrokeFromOptions:(NSArray*)options withPrimary:(XVimKeyStroke*)primaryKeyStroke
{
	NSArray* ret = NULL;
	
	for (XVimKeyStroke* option in options)
	{
		ret = [_dict objectForKey:option];
		if (ret) break;
	}
	
	ret = ret ? ret : [NSArray arrayWithObject:primaryKeyStroke];
	
	return ret;
}

@end
