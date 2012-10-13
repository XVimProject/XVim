//
//  XVimHookManager.h
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVimHookManager : NSObject
+ (void)hookWhenPluginLoaded;
+ (void)hookWhenDidFinishLaunching;
@end
