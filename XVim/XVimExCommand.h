//
//  XVimExCommand.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Xvim.h"

@interface XVimExCommand : NSObject{
    NSDictionary* _excommands;
}

- (id)init;
- (void)executeCommand:(NSString*)cmd withXVim:(XVim*)xvim;
@end
