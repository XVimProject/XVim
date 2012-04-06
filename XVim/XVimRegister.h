//
//  XVimRegister.h
//  XVim
//
//  Created by Nader Akoury on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    REGISTER_IGNORE,
    REGISTER_APPEND,
    REGISTER_REPLACE
} XVimRegisterOperation;

@class XVimKeyStroke;

@interface XVimRegister : NSObject

-(id) initWithRegisterName:(NSString*)registerName displayName:(NSString*)displayName;

-(void) playback:(NSView*)view withRepeatCount:(NSUInteger)count;
-(void) appendKeyEvent:(XVimKeyStroke*)keyStroke;
-(void) appendText:(NSString*)text;
-(void) clear;

@property (readonly, strong) NSMutableString *text;
@property (readonly, strong) NSString *name;
@property (readonly, strong) NSString *displayName;
@property (readonly) BOOL isAlpha;
@property (readonly) BOOL isNumeric;
@property (readonly) BOOL isRepeat;
@property (readonly) BOOL isReadOnly;
@property (readonly) NSUInteger keyCount;
@property (readonly) NSUInteger numericKeyCount;
@property (readonly) NSUInteger nonNumericKeyCount;

@end
