//
//  XVimPlaybackDevice.h
//  XVim
//
//  Created by Tomas Lundell on 7/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimKeyStroke;

@protocol XVimPlaybackHandler<NSObject>
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke;
- (void)handleTextInsertion:(NSString*)text;
@end
