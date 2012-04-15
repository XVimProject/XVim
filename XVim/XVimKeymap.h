//
//  XVimKeymap.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimKeyStroke;
@class XVimKeymapNode;

@interface XVimKeymap : NSObject
- (void)mapKeyStroke:(NSArray*)keyStrokes to:(NSArray*)targetKeyStrokes;

- (NSArray*)lookupKeyStrokeFromOptions:(NSArray*)options 
						   withPrimary:(XVimKeyStroke*)primaryKeyStroke
						   withContext:(XVimKeymapNode**)context;
@end
