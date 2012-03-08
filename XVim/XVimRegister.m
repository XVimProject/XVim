//
//  XVimRegister.m
//  XVim
//
//  Created by Nader Akoury on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegister.h"

@implementation XVimRegister

NSString *_name;
@synthesize text = _text;

-(NSString*) name{
    return _name;
}

-(id) initWithRegisterName:(NSString*)registerName{
    self = [super init];
    if (self) {
        _text = [[NSMutableString alloc] initWithString:@""];
        _name = [[NSString alloc] initWithString:registerName];
    }
    return self;
}

@end
