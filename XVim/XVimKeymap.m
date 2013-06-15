//
//  XVimKeymap.m
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeymap.h"
#import "XVimKeyStroke.h"


//// Internal Class XVimKeymapNode ////
/**
 *  This class represents a node in key map trie.
 **/
@interface XVimKeymapNode : NSObject {
}
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

- (void)map:(XVimString*)keyStrokes to:(XVimString*)targetKeyStrokes withRemap:(BOOL)remap{
    // Create key map trie
    XVimKeymapNode* current = self.root;
    NSArray* strokes = [keyStrokes toKeyStrokes];
    for( XVimKeyStroke* stroke in strokes ){
		XVimKeymapNode *nextNode = [current.dict objectForKey:stroke];
		if (!nextNode){
			nextNode = [[[XVimKeymapNode alloc] init] autorelease];
			[current.dict setObject:nextNode forKey:stroke];
		}
		current = nextNode;
    }
	current.target = targetKeyStrokes;
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
    [self unmapImpl:[NSMutableArray arrayWithArray:[str toKeyStrokes]] atNode:self.root];
}

/**
 *  This method map key input to the current key map.
 *  If it maps to "remappable" keymap it calls recursively to fix the map.
 **/
- (XVimString*)mapKeys:(XVimString*)keys withContext:(XVimKeymapContext*)context forceFix:(BOOL)fix{
    NSArray* strokes = [keys toKeyStrokes];
    if( context.node == nil ){
        context.node = self.root;
    }
	XVimKeymapNode *node = context.node;
	XVimKeymapNode *nextNode = nil;
    XVimString* unProcessedString = nil; // This will get un-nil when not all the strokes are processed in following loop
	for ( NSUInteger i = 0 ; i < strokes.count; i++ ){
        XVimKeyStroke* stroke = [strokes objectAtIndex:i];
        // Walk through mapping node
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
            unProcessedString = [XVimKeyStroke keyStrokesToXVimString:[strokes subarrayWithRange:NSMakeRange(i, strokes.count-i)]];
            break;
        }
        node = nextNode;
	}
    
    // |    inputKeys                  |  unProcessedKeys  |
    // |    lastMappedKeys  |
    // will be converted to
    // |    targetKeys |  unmappedKeys |  unProcessedKeys  |
    
    if( fix || !node.hasChild || unProcessedString != nil ){
        // No more nodes to follow.
        // Fix the keymapping
        if( context.lastMappedNode != nil ){
            XVimString* newStr = [NSString stringWithFormat:@"%@%@%@", context.lastMappedNode.target, context.unmappedKeys, unProcessedString];
            if( context.lastMappedNode.remap ){
                XVimKeymapContext* context = [[[XVimKeymapContext alloc] init] autorelease];
                return [self mapKeys:newStr withContext:context forceFix:fix];
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


@end