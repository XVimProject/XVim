//
//  XVimRegister.m
//  XVim
//
//  Created by Nader Akoury on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegister.h"
#import "XVimEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimPlaybackHandler.h"
#import "XVim.h"
#import "Logger.h"

@interface XVimRegister() {
	NSRange _selectedRange;
	VISUAL_MODE _visualMode;
    NSMutableString* _text;
}
@property (readwrite) BOOL isPlayingBack;
@property (strong) NSMutableArray *keyEventsAndInsertedText;
@end

@implementation XVimRegister

@synthesize displayName = _displayName;
@synthesize isPlayingBack = _isPlayingBack;
@synthesize keyEventsAndInsertedText = _keyEventsAndInsertedText;
@synthesize nonNumericKeyCount = _nonNumericKeyCount;

-(void)setText:(NSMutableString*)text
{
	@synchronized(self)
	{
		if( ![_displayName isEqualToString:@"%"] ) {
			if( text != _text ){
				[_text release];
				_text = [text retain];
			}
		} else {
			ERROR_LOG( "assert!" );
		}
	}
}

-(NSMutableString*)text
{
	@synchronized(self)
	{
		if( [_displayName isEqualToString:@"%"] ){
            // current file name register
			return [NSMutableString stringWithString:[XVim instance].document];
		} else {
			return [[_text retain] autorelease];
		}
	}
}

-(NSString*) description{
    return [[NSString alloc] initWithFormat:@"\"%@: %@", self.displayName, self.text];
}

-(id) initWithDisplayName:(NSString*)displayName
{
    self = [super init];
    if (self) {
        _keyEventsAndInsertedText = [[NSMutableArray alloc] init];
        _text = [NSMutableString stringWithString:@""];
        _displayName = [NSString stringWithString:displayName];
        _nonNumericKeyCount = 0;
        _isPlayingBack = NO;
		_selectedRange.location = NSNotFound;
    }
    return self;
}

-(BOOL) isAlpha{
    if (self.displayName.length != 1){
        return NO;
    }
    unichar charcode = [self.displayName characterAtIndex:0];
    return (65 <= charcode && charcode <= 90) || (97 <= charcode && charcode <= 122);
}

-(BOOL) isNumeric{
    if (self.displayName.length != 1){
        return NO;
    }
    unichar charcode = [self.displayName characterAtIndex:0];
    return (48 <= charcode && charcode <= 57);
}

-(BOOL) isRepeat{
    return [self.displayName isEqualToString:@"repeat"];
}

-(BOOL) isReadOnly{
    BOOL readonly;
    NSCharacterSet *readonlyTokenCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@":.%#"];
    if ([_displayName length] == 1) {
        unichar character = [_displayName characterAtIndex:0];
        readonly = [readonlyTokenCharacterSet characterIsMember:character];
    } else {
        readonly = NO;
    }
    
    return readonly || self.isRepeat;
}

-(BOOL) isEqual:(id)object{
    return [object isKindOfClass:[self class]] && [self hash] == [object hash];
}

-(NSUInteger) hash{
    return [self.displayName hash];
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
	_selectedRange.location = NSNotFound;
    [self.text setString:@""];
    [self.keyEventsAndInsertedText removeAllObjects];
}

-(void) appendKeyEvent:(XVimKeyStroke*)keyStroke{
    if (self.isPlayingBack){
        return;
    }

    NSString *key = [keyStroke toSelectorString];
    if (key.length > 1){
        [self.text appendString:[NSString stringWithFormat:@"<%@>", key]];
    }else{
        [self.text appendString:key];
    }
    if (!keyStroke.isNumeric){
        ++_nonNumericKeyCount;
    }
    [self.keyEventsAndInsertedText addObject:keyStroke];
}

-(void) appendText:(NSString*)text{
    if (self.isPlayingBack){
        return;
    }

    [self.text appendString:text];
    [self.keyEventsAndInsertedText addObject:text];
}

-(void) setVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range
 {
	if (self.isPlayingBack){
		return;
	}
	_selectedRange = range;
	_visualMode = mode;
}

-(void) playbackWithHandler:(id<XVimPlaybackHandler>)handler withRepeatCount:(NSUInteger)count{
    self.isPlayingBack = YES;
	
	if (_selectedRange.location != NSNotFound)
	{
		[handler handleVisualMode:_visualMode withRange:_selectedRange];
	}
	
    for (NSUInteger i = 0; i < count; ++i) {
        [self.keyEventsAndInsertedText enumerateObjectsUsingBlock:^(id eventOrText, NSUInteger index, BOOL *stop){        
            if ([eventOrText isKindOfClass:[XVimKeyStroke class]]){
				[handler handleKeyStroke:(XVimKeyStroke*)eventOrText];
            }else if([eventOrText isKindOfClass:[NSString class]]){
                [handler handleTextInsertion:(NSString*)eventOrText];
            }
        }];
    }
    self.isPlayingBack = NO;
}

@end
