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

@interface XVimRegister()
@property (readwrite) BOOL isPlayingBack;
@property (strong) NSMutableArray *keyEventsAndInsertedText;
@end

@implementation XVimRegister

@synthesize text = _text;
@synthesize name = _name;
@synthesize isPlayingBack = _isPlayingBack;
@synthesize keyEventsAndInsertedText = _keyEventsAndInsertedText;
@synthesize nonNumericKeyCount = _nonNumericKeyCount;

-(NSString*) description{
    return [[NSString alloc] initWithFormat:@"\"%@: %@", self.name, self.text];
}

-(id) initWithRegisterName:(NSString*)registerName{
    self = [super init];
    if (self) {
        _keyEventsAndInsertedText = [[NSMutableArray alloc] init];
        _text = [NSMutableString stringWithString:@""];
        _name = [NSString stringWithString:registerName];
        _nonNumericKeyCount = 0;
        _isPlayingBack = NO;
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

-(BOOL) isReadOnly{
    return self.name == @":" || self.name == @"." || self.name == @"%" || self.name == @"#" || self.isRepeat;
}

-(BOOL) isEqual:(id)object{
    return [object isKindOfClass:[self class]] && [self hash] == [object hash];
}

-(NSUInteger) hash{
    return [self.name hash];
}

-(NSUInteger) keyCount{
    return self.keyEventsAndInsertedText.count;
}

-(NSUInteger) numericKeyCount{
    return self.keyCount - self.nonNumericKeyCount;
}

-(NSUInteger) nonNumericKeyCount{
    return _nonNumericKeyCount;
}

-(void) clear{
    if (self.isPlayingBack){
        return;
    }

    _nonNumericKeyCount = 0;
    [self.text setString:@""];
    [self.keyEventsAndInsertedText removeAllObjects];
}

-(void) appendKeyEvent:(NSEvent*)event{
    if (self.isPlayingBack){
        return;
    }

    NSString *key = [XVimEvaluator keyStringFromKeyEvent:event];
    if (key.length > 1){
        [self.text appendString:[NSString stringWithFormat:@"<%@>", key]];
    }else{
        [self.text appendString:key];
    }
    if ([XVimEvaluator isNumericKey:event] == NO){
        ++_nonNumericKeyCount;
    }
    [self.keyEventsAndInsertedText addObject:event];
}

-(void) appendText:(NSString*)text{
    if (self.isPlayingBack){
        return;
    }

    [self.text appendString:text];
    [self.keyEventsAndInsertedText addObject:text];
}

-(void) playback:(NSView*)view withRepeatCount:(NSUInteger)count{
    self.isPlayingBack = YES;
    for (NSUInteger i = 0; i < count; ++i) {
        [self.keyEventsAndInsertedText enumerateObjectsUsingBlock:^(id eventOrText, NSUInteger index, BOOL *stop){        
            if ([eventOrText isKindOfClass:[NSEvent class]]){
                // Send the keyDown event directly to the view
                [view keyDown:eventOrText];
            }else if([eventOrText isKindOfClass:[NSString class]]){
                [view insertText:eventOrText];
            }
        }];
    }
    self.isPlayingBack = NO;
}

@end
