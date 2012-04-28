//
//  XVimPlaybackDevice.h
//  XVim
//
//  Created by Tomas Lundell on 7/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimVisualMode.h"

@class XVimKeyStroke;

@protocol XVimPlaybackHandler<NSObject>
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke;
- (void)handleTextInsertion:(NSString*)text;
- (void)handleVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range;
@end
