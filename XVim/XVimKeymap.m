//
//  XVimKeymap.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeymap.h"
#import "XVimKeyStroke.h"

@class XVimKeymapNode;

@interface XVimKeymapContext() {
@public
	NSMutableArray *_absorbedKeys;
	XVimKeymapNode *_node;
}
@end

@implementation XVimKeymapContext

- (id)init
{
	if (self = [super init])
	{
		_absorbedKeys = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)clear
{
	[_absorbedKeys removeAllObjects];
	_node = nil;
}

- (NSString*)toString
{
	NSString *ret = @"";
	for (XVimKeyStroke *keyStroke in _absorbedKeys)
	{
		ret = [ret stringByAppendingString:[keyStroke toString]];
	}
	return ret;
}

- (NSMutableArray *)absorbedKeys {
    return _absorbedKeys;
}

@end

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
						   withContext:(XVimKeymapContext*)context
{
	NSArray *ret = nil;
	XVimKeymapNode *node = context->_node;
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
			[context clear];
		} else {
			[context->_absorbedKeys addObject:primaryKeyStroke];
			context->_node = foundNode;
		}
		
	} else {
		NSMutableArray *objects = [NSMutableArray arrayWithArray:context->_absorbedKeys];
		[objects addObject:primaryKeyStroke];
		[context clear];
		
		ret = objects;
	}
	
	return ret;
}

@end