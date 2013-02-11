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

@implementation XVimKeymapContext
@synthesize absorbedKeys = _absorbedKeys;
@synthesize node = _node;

- (id)init
{
	if (self = [super init])
	{
		_absorbedKeys = [[NSMutableArray alloc] init];
        _node = nil;
	}
	return self;
}

- (void)dealloc
{
    [_absorbedKeys release];
    [_node release];
    [super dealloc];
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

@end

@interface XVimKeymapNode : NSObject {
	NSMutableDictionary *_dict;
	NSArray *_target;
}

@property (nonatomic, retain) NSMutableDictionary *dict;
@property (nonatomic, retain) NSArray *target;
@end

@implementation XVimKeymapNode
@synthesize dict = _dict;
@synthesize target = _target;
- (id)init
{
	if (self = [super init])
	{
		_dict = [[NSMutableDictionary alloc] init];
        _target = nil;
	}
	return self;
}
- (void)dealloc
{
    [_dict release];
    [_target release];
    [super dealloc];
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

- (void)dealloc
{
    [_node release];
    [super dealloc];
}

- (void)mapKeyStroke:(NSArray*)keyStrokes to:(NSArray*)targetKeyStrokes
{
	XVimKeymapNode *node = _node;
	for (XVimKeyStroke *keyStroke in keyStrokes)
	{
		XVimKeymapNode *nextNode = [node.dict objectForKey:keyStroke];
		if (!nextNode)
		{
			nextNode = [[[XVimKeymapNode alloc] init] autorelease];
			[node.dict setObject:nextNode forKey:keyStroke];
		}
		node = nextNode;
	}
	node.target = targetKeyStrokes;
}

- (NSArray*)lookupKeyStrokeFromOptions:(NSArray*)options 
						   withPrimary:(XVimKeyStroke*)primaryKeyStroke
						   withContext:(XVimKeymapContext*)context
{
	NSArray *ret = nil;
	XVimKeymapNode *node = context.node;
	if (!node) { node = _node; }
	
	XVimKeymapNode *foundNode = nil;
	
	for (XVimKeyStroke* option in options)
	{
		foundNode = [node.dict objectForKey:option];
		if (foundNode) { break; }
	}
	
	if (foundNode) {
		// Leaf node?
		if ([foundNode.dict count] == 0) {
			ret = foundNode.target;
			[context clear];
		} else {
			[context.absorbedKeys addObject:primaryKeyStroke];
			context.node = foundNode;
		}
		
	} else {
		NSMutableArray *objects = [NSMutableArray arrayWithArray:context.absorbedKeys];
		[objects addObject:primaryKeyStroke];
		[context clear];
		
		ret = objects;
	}
	
	return ret;
}

@end