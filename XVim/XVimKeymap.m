//
//  XVimKeymap.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeymap.h"
#import "XVimKeyStroke.h"
#import "Logger.h"


//// Internal Class XVimKeymapNode ////
// This class represents a node in key map trie.

@interface XVimKeymapNode : NSObject
@property (nonatomic, retain) NSMutableDictionary *dict;
@property                     BOOL remap;
@property (nonatomic, retain) XVimString* target;
- (BOOL)hasChild;
@end

@implementation XVimKeymapNode
- (id)init{
	if (self = [super init]){
		self.dict = [[[NSMutableDictionary alloc] init] autorelease];
        self.target = nil;
	}
	return self;
}

- (void)dealloc{
    self.dict = nil;
    self.target = nil;
    [super dealloc];
}

- (BOOL)hasChild{
    return 0 != self.dict.count;
}

@end
//// XVimKeymapNode End ////


@implementation XVimKeymapContext
- (id)init {
	if (self = [super init]){
		self.inputKeys = [[[NSMutableString alloc] init] autorelease];
		self.lastMappedKeys = [[[NSMutableString alloc] init] autorelease];
		self.lastMappedNode = nil;
        self.node = nil;
	}
	return self;
}

- (void)dealloc {
    self.inputKeys = nil;
	self.lastMappedKeys = nil;
    self.lastMappedNode = nil;
    self.node = nil;
    [super dealloc];
}

- (void)clear {
	[self.inputKeys setString:@""];
	[self.lastMappedKeys setString:@""];
    self.lastMappedNode = nil;
	self.node = nil;
}

- (XVimString*)unmappedKeys{
    NSAssert([self.lastMappedKeys length] == 0 ||  [self.inputKeys hasPrefix:self.lastMappedKeys], @"lastMappedKeys must be a prefix of inputKeys! Must be a programming error");
    return [self.inputKeys substringWithRange:NSMakeRange(self.lastMappedKeys.length, self.inputKeys.length - self.lastMappedKeys.length)];
}

@end



@interface XVimKeymap()
@property(retain) XVimKeymapNode* root;
@end

@implementation XVimKeymap
- (id)init{
	self = [super init];
	if (self) {
        self.root = [[[XVimKeymapNode alloc] init] autorelease];
	}
	return self;
}

- (void)dealloc{
    self.root = nil;
    [super dealloc];
}

- (void)mapsInNode:(XVimKeymapNode*)node :(NSString*)mappingKey :(NSMutableDictionary*)dictionary{
    if( node.target != nil ){
        [dictionary setObject:node.target forKey:mappingKey];
    }
    for(XVimKeyStroke* key in node.dict){
        XVimKeymapNode* next = [node.dict objectForKey:key];
        NSString* nextMap = [mappingKey stringByAppendingFormat:@"%C", key.character];
        [self mapsInNode:next :nextMap :dictionary];
    }
}

- (NSDictionary*)mapsInNode{
    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
    [self mapsInNode:self.root :@"" :dict];
    return dict;
}

- (void)map:(XVimString*)keyStrokes to:(XVimString*)targetKeyStrokes withRemap:(BOOL)remap{
    // Create key map trie
    XVimKeymapNode* current = self.root;
    NSArray* strokes = XVimKeyStrokesFromXVimString(keyStrokes);
    for( XVimKeyStroke* stroke in strokes ){
		XVimKeymapNode *nextNode = [current.dict objectForKey:stroke];
		if (!nextNode){
			nextNode = [[[XVimKeymapNode alloc] init] autorelease];
			[current.dict setObject:nextNode forKey:stroke];
		}
		current = nextNode;
    }
	current.target = targetKeyStrokes;
    current.remap = remap;
    
    [self mapsInNode];
}

- (void)unmapImpl:(NSMutableArray*)keystrokes atNode:(XVimKeymapNode*)node{
    NSAssert( nil != keystrokes, @"must not be nil");
    NSAssert( nil != node, @"must not be nil");
    
    XVimKeymapNode* nextNode = nil;
    XVimKeyStroke* stroke = nil;
    if( keystrokes.count != 0 ){
        stroke = [keystrokes objectAtIndex:0];
        nextNode = [node.dict objectForKey:stroke];
        if( nextNode ){
            // Go to most deep node recursively
            [keystrokes removeObjectAtIndex:0];
            [self unmapImpl:keystrokes atNode:nextNode];
            if( nextNode.dict.count == 0 && nextNode.target == nil ){
                // If the node does not have child and target we do not need to have it.
                [node.dict removeObjectForKey:stroke];
            }
        }else{
            // There is no node to follow ( maybe unmapping non-mapped key )
            // Just do nothing
        }
    }else{
        // This is the last node of the map( means most deep node of the keymap to unmap). Just delete target (this node is deleted on upper node processing if thid node does not have child any more)
        node.target = nil;
    }
}

- (void)unmap:(XVimString*)str{
    NSAssert( nil != str, @"str must not be nil" );
    if( str.length == 0 ){
        return;
    }
    [self unmapImpl:[NSMutableArray arrayWithArray:XVimKeyStrokesFromXVimString(str)] atNode:self.root];
}

- (void)clear{
    [self.root.dict removeAllObjects];
}

/**
 *  This method map key input to the current key map.
 *  If it maps to "remappable" keymap it calls recursively to fix the map.
 **/
- (XVimString*)mapKeys:(XVimString*)keys withContext:(XVimKeymapContext*)context forceFix:(BOOL)fix{
    NSArray* strokes = XVimKeyStrokesFromXVimString(keys);
    if( context.node == nil ){
        context.node = self.root;
    }
    
    // Walk through mapping node
	XVimKeymapNode *node = context.node; // current node
	XVimKeymapNode *nextNode = nil;      // next node to walk to
    XVimString* unProcessedString = @""; // if a node does not have any path to walk rest of input keys are stored to this variable.
	for ( NSUInteger i = 0 ; i < strokes.count; i++ ){
        XVimKeyStroke* stroke = [strokes objectAtIndex:i];
        nextNode = [node.dict objectForKey:stroke];
		if (nil != nextNode){
            // If there is a node to follow
            [context.inputKeys appendString:[stroke xvimString]];
            if( nextNode.target != nil ){
                [context.lastMappedKeys setString:context.inputKeys];
                context.lastMappedNode = nextNode;
            }
        }else{
            // No node to follow
            // Keep rest of input
            unProcessedString = XVimStringFromKeyStrokes([strokes subarrayWithRange:NSMakeRange(i, strokes.count-i)]);
            break;
        }
        node = nextNode;
	}
    
    // Update context in case the input are not fixed yet and use it later
    context.node = node;
    
    // |    inputKeys                  |  unProcessedKeys  |
    // |    lastMappedKeys  |
    // will be converted to
    // |    targetKeys |  unmappedKeys |  unProcessedKeys  |
    
    // If there is no node to follow (or force fix flag is on)
    // we fix the input and return mapped keys
    
    static NSUInteger infinit_loop_guard = 1000; // TODO: This should be implemented as "maxmapdepth" value
    
    if( fix || !node.hasChild || unProcessedString.length != 0){
        // No more nodes to follow.
        // Fix the keymapping
        if( context.lastMappedNode != nil ){
            XVimString* newStr = [NSString stringWithFormat:@"%@%@%@", context.lastMappedNode.target, context.unmappedKeys, unProcessedString];
            if( context.lastMappedNode.remap && infinit_loop_guard != 0){
                // Key remapping
                XVimKeymapContext* context = [[[XVimKeymapContext alloc] init] autorelease];
                infinit_loop_guard--;
                NSString* map = [self mapKeys:newStr withContext:context forceFix:fix];
                infinit_loop_guard++;
                return map;
            }else{
                // No more mapping
                return newStr;
            }
        }else{
            // No map needed
            return [XVimString stringWithFormat:@"%@%@", context.inputKeys, unProcessedString];
        }
    }
    
    // We still need to wait next key input
    return nil;
}

- (void)enumerateKeymapsImpl:(XVimKeymapNode*)node forKeys:(XVimString*)keys withBlock:(void (^)(NSString *, NSString *))block{
    if( node.target != nil ){
        NSString* toKey   = [XVimString stringWithFormat:@"%@%@" , node.remap?@"":@"* ", XVimKeyNotationFromXVimString(node.target)];
         block( keys,  toKey);
    }
    
    [node.dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        XVimKeyStroke* stroke = key;
        [self enumerateKeymapsImpl:obj forKeys:[XVimString stringWithFormat:@"%@%@", keys, [stroke keyNotation]] withBlock:block];
    }];
}
- (void)enumerateKeymaps:(void (^)(NSString* mapFrom, NSString* mapTo))block{
    [self enumerateKeymapsImpl:self.root forKeys:@"" withBlock:block];
}

@end