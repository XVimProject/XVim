//
//  XVimKeymap.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimKeyStroke, XVimKeymapNode;

@interface XVimKeymapContext : NSObject {
    NSMutableArray *_absorbedKeys;
	XVimKeymapNode *_node;
}

@property (nonatomic, retain) NSMutableArray *absorbedKeys;
@property (nonatomic, retain) XVimKeymapNode *node;

- (void)clear;
- (NSString*)toString;

@end

@interface XVimKeymap : NSObject
- (void)mapKeyStroke:(NSArray*)keyStrokes to:(NSArray*)targetKeyStrokes;

- (NSArray*)lookupKeyStrokeFromOptions:(NSArray*)options 
						   withPrimary:(XVimKeyStroke*)primaryKeyStroke
						   withContext:(XVimKeymapContext*)context;
@end
