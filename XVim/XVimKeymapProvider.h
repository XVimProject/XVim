//
//  XVimKeymapProvider.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimKeymap;

@protocol XVimKeymapProvider <NSObject>
- (XVimKeymap*)keymapForMode:(int)mode;
@end
