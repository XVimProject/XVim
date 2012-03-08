//
//  XVimRegister.h
//  XVim
//
//  Created by Nader Akoury on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVimRegister : NSObject

-(id) initWithRegisterName:(NSString*)name;

@property (strong) NSMutableString *text;
@property (readonly, strong) NSString *name;

@end
