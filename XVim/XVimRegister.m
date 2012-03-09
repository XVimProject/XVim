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

-(NSString*) description{
    return [[NSString alloc] initWithFormat:@"\"%@: %@", self.name, self.text];
}

-(id) initWithRegisterName:(NSString*)registerName{
    self = [super init];
    if (self) {
        _text = [[NSMutableString alloc] initWithString:@""];
        _name = [[NSString alloc] initWithString:registerName];
    }
    return self;
}

-(BOOL) isAlpha{
    if (self.name.length != 1){
        return NO;
    }
    unichar charcode = [self.name characterAtIndex:0];
    return (65 <= charcode && charcode <= 90) || (97 <= charcode && charcode <= 122);
}

-(BOOL) isNumeric{
    if (self.name.length != 1){
        return NO;
    }
    unichar charcode = [self.name characterAtIndex:0];
    return (48 <= charcode && charcode <= 57);
}

-(BOOL) isRepeat{
    return self.name == @"repeat";
}

@end
