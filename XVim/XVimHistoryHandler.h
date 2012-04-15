//
//  XVimHistoryHandler.h
//  XVim
//
//  Created by Tomas Lundell on 15/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVimHistoryHandler : NSObject
- (void)addEntry:(NSString*)entry;
- (NSString*) entry:(NSUInteger)no withPrefix:(NSString*)str;
@end
