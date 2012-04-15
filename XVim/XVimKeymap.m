//
//  XVimKeymap.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeymap.h"
#import "XVimKeyStroke.h"

@interface XVimKeymapNode : NSObject {
@public
	NSMutableDictionary *_dict;
	NSArray *_target;
}
@end

@implementation XVimKeymapNode
- (id)init
{
	if (self = [super init])
	{
		_dict = [[NSMutableDictionary alloc] init];
	}
	return self;
}
@end

@interface XVimKeymap() {
	XVimKeymapNode* _node;
}
@end

@implementation XVimKeymap
- (id)init
{
	self = [super init];
	if (self) {
		_node = [[XVimKeymapNode alloc] init];
	}
	return self;
}

- (void)mapKeyStroke:(NSArray*)keyStrokes to:(NSArray*)targetKeyStrokes
{
	XVimKeymapNode *node = _node;
	for (XVimKeyStroke *keyStroke in keyStrokes)
	{
		XVimKeymapNode *nextNode = [node->_dict objectForKey:keyStroke];
		if (!nextNode)
		{
			nextNode = [[XVimKeymapNode alloc] init];
			[node->_dict setObject:nextNode forKey:keyStroke];
		}
		node = nextNode;
	}
	node->_target = targetKeyStrokes;
}

- (NSArray*)lookupKeyStrokeFromOptions:(NSArray*)options 
						   withPrimary:(XVimKeyStroke*)primaryKeyStroke
						   withContext:(XVimKeymapNode**)context
{
	NSArray *ret = nil;
	XVimKeymapNode *node = *context;
	if (!node) { node = _node; }
	
	XVimKeymapNode *foundNode = nil;
	
	for (XVimKeyStroke* option in options)
	{
		foundNode = [node->_dict objectForKey:option];
		if (foundNode) { break; }
	}
	
	if (foundNode) {
		// Leaf node?
		if ([foundNode->_dict count] == 0) {
			ret = foundNode->_target;
			foundNode = NULL;
		}
	} else {
		ret = [NSArray arrayWithObject:primaryKeyStroke];
	}
	
	*context = foundNode;
	
	return ret;
}

@end
