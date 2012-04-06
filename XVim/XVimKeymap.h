//
//  XVimKeymap.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimKeyStroke;

@interface XVimKeymap : NSObject
- (void)mapKeyStroke:(XVimKeyStroke*)keyStroke to:(NSArray*)targetKeyStrokes;
- (NSArray*)lookupKeyStroke:(XVimKeyStroke*)keyStroke;
@end
