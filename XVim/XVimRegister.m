//
//  XVimRegister.m
//  XVim
//
//  Created by Nader Akoury on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegister.h"
#import "XVimEvaluator.h"
#import <CoreServices/CoreServices.h>

@implementation XVimRegister

NSString *_name;
NSMutableArray *_keyEvents;
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
        _keyEvents = [[NSMutableArray alloc] init];
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

-(NSUInteger) keyCount{
    return _keyEvents.count;
}

-(void) clear{
    [self.text setString:@""];
    [_keyEvents removeAllObjects];
}

-(void) appendKeyEvent:(NSEvent*)event{
    NSString *key = [XVimEvaluator keyStringFromKeyEvent:event];
    if (key.length > 1){
        [self.text appendString:[NSString stringWithFormat:@"<%@>", key]];
    }else{
        [self.text appendString:key];
    }
    [_keyEvents addObject:event];
}

-(void) playback:(NSView*)view withRepeatCount:(NSUInteger)count{
    for (NSUInteger i = 0; i < count; ++i) {
        [_keyEvents enumerateObjectsUsingBlock:^(NSEvent *event, NSUInteger index, BOOL *stop){        
            // Have to clone the event with a new time stamp in order to not confuse the app
            // otherwise it can cause a crash or simply ignore the repeat count. Unfortunately
            // it posts the events VERY SLOWLY. Need to find a better way to speed it up.
            NSTimeInterval currentTime = 0.01 * AbsoluteToDuration(UpTime());
            NSEvent *clonedEvent = [NSEvent keyEventWithType:event.type location:event.locationInWindow modifierFlags:event.modifierFlags timestamp:currentTime  windowNumber:event.windowNumber context:event.context characters:event.characters charactersIgnoringModifiers:event.charactersIgnoringModifiers isARepeat:event.isARepeat keyCode:event.keyCode];
            [[NSApplication sharedApplication] postEvent:clonedEvent atStart:NO];
        }];
    }
}

@end
