//
//  XVimKeyStroke.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeyStroke.h"

static char* keynames[] = {
    "NUL",
    "SOH",
    "STX",
    "ETX",
    "EOT",
    "ENQ",
    "ACK",
    "BEL",
    "BS",
    "HT",
    "NL",
    "VT",
    "NP",
    "CR",
    "SO",
    "SI",
    "DLE",
    "DC1",
    "DC2",
    "DC3",
    "DC4",
    "NAK",
    "SYN",
    "ETB",
    "CAN",
    "EM",
    "SUB",
    "ESC",
    "FS",
    "GS",
    "RS",
    "US",
    "SPACE",
    "EXCLAMATION",
    "DQUOTE",
    "NUMBER",
    "DOLLAR",
    "PERCENT",
    "AMPERSAND",
    "SQUOTE",
    "LPARENTHESIS",
    "RPARENTHESIS",
    "ASTERISK",
    "PLUS",
    "COMMA",
    "MINUS",
    "DOT",
    "SLASH",
    "NUM0",
    "NUM1",
    "NUM2",
    "NUM3",
    "NUM4",
    "NUM5",
    "NUM6",
    "NUM7",
    "NUM8",
    "NUM9",
    "COLON",
    "SEMICOLON",
    "LESSTHAN",
    "EQUAL",
    "GREATERTHAN",
    "QUESTION",
    "AT",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "LSQUAREBRACKET",
    "BACKSLASH",
    "RSQUAREBRACKET",
    "CARET",
    "UNDERSCORE",
    "BACKQUOTE",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "LBRACE", // {
    "VERTICALLINE", // |
    "RBRACE", // }
    "TILDE", // ~
    "DEL"
};

static NSMutableDictionary *s_keyCodeToSelectorString = NULL;
static NSMutableDictionary *s_stringToKeyCode = NULL;

@implementation XVimKeyStroke
@synthesize key = _key;
@synthesize modifierFlags = _modifierFlags;

- (BOOL) isNumeric{
    NSString *keyStr = [self toSelectorString];
    return [keyStr hasPrefix:@"NUM"] && [keyStr length] == 4;
}

+ (void)initKeyCodeToSelectorString
{
	if (!s_keyCodeToSelectorString)
	{
		NSMutableDictionary *keyCodeToSelectorString = [[NSMutableDictionary alloc] init];
		s_keyCodeToSelectorString = keyCodeToSelectorString;
		
		void (^map) (NSString *, int) = ^(NSString *key, int i)
		{
			[keyCodeToSelectorString setObject:key forKey:[NSNumber numberWithInt:i]];
		};
		
		for (int i = 0; i < 128; ++i)
		{
			NSString *string = [NSString stringWithCString:keynames[i] encoding:NSASCIIStringEncoding];
			map(string, i);
		}
		
		map(@"Up", 63232);
		map(@"Down", 63233);
		map(@"Left", 63234);
		map(@"Right", 63235);
	}
}

+ (void)initStringToKeyCode
{
	if (!s_stringToKeyCode)
	{
		NSMutableDictionary *stringToKeyCode = [[NSMutableDictionary alloc] init];
		s_stringToKeyCode = stringToKeyCode;
		
		void (^map) (NSString *, int) = ^(NSString *key, int i)
		{
			[stringToKeyCode setObject:[NSNumber numberWithInt:i] forKey:key];
		};
		
		// Map the selector names - we uppercase all of these to make them case insensitive
		for (int i = 0; i <= 32; ++i)
		{
			NSString *string = [NSString stringWithCString:keynames[i] encoding:NSASCIIStringEncoding];
			map([string uppercaseString], i);
		}
		map(@"UP", 63232);
		map(@"DOWN", 63233);
		map(@"LEFT", 63234);
		map(@"RIGHT", 63235);
		
		// Between space and del (non-inclusive), add ascii names
		for (int i = 33; i < 127; ++i)
		{
			unichar c = i;
			NSString *string = [NSString stringWithCharacters:&c length:1];
			map(string, i);
		}
	}
}

+ (void)initKeymaps
{
	[self initKeyCodeToSelectorString];
	[self initStringToKeyCode];
}

- (NSUInteger)hash
{
	return self.modifierFlags + self.key;
}

- (BOOL)isEqual:(id)object
{
	if (object == self) {
		return YES;
	}	
	if (!object || ![object isKindOfClass:[self class]])
	{
		return NO;
	}
	XVimKeyStroke* other = object;
	return self.key == other.key && self.modifierFlags == other.modifierFlags;
}

- (id)copyWithZone:(NSZone *)zone {
	XVimKeyStroke* copy = [[XVimKeyStroke allocWithZone:zone] init];
	copy.key = self.key;
	copy.modifierFlags = self.modifierFlags;
	return copy;
}

+ (XVimKeyStroke*)fromEvent:(NSEvent*)event
{
	XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] init];
	keyStroke.key = [event.characters characterAtIndex:0];
	keyStroke.modifierFlags = event.modifierFlags & 
		(NSShiftKeyMask | NSControlKeyMask | NSCommandKeyMask | NSAlternateKeyMask);
	return keyStroke;
}

- (NSEvent*)toEvent
{
	unichar c = self.key;
	NSString *characters = [NSString stringWithCharacters:&c length:1];
	int mflags = self.modifierFlags;
	
	NSEvent*  e = [NSEvent keyEventWithType:NSKeyDown 
								   location:NSMakePoint(0, 0)
							  modifierFlags:mflags
								  timestamp:0
							   windowNumber:0
									context:nil
								 characters:characters
				charactersIgnoringModifiers:characters
								  isARepeat:NO 
									keyCode:0];
	return e;
}

static NSString* toSelectorString(unichar charcode, int modifierFlags)
{
	// S- Shift
	// C- Control
	// M- Option
	// D- Command
	NSMutableString* keyStr = [[[NSMutableString alloc] init] autorelease];
	if( modifierFlags & NSShiftKeyMask ){
		[keyStr appendString:@"S_"];
	}
	if( modifierFlags & NSControlKeyMask ){
		[keyStr appendString:@"C_"];
	}
	if( modifierFlags & NSAlternateKeyMask ){
		[keyStr appendString:@"M_"];
	}
	if( modifierFlags & NSCommandKeyMask ){
		[keyStr appendString:@"D_"];
	}
	
	NSString *keyname = [s_keyCodeToSelectorString objectForKey:[NSNumber numberWithInt:charcode]];
	if (keyname) { 
		[keyStr appendString:keyname];
	}
	
	return keyStr;
}

- (NSString*) toSelectorString {
	return toSelectorString(self.key, self.modifierFlags);
}

- (NSString*)description {
	return [self toSelectorString];
}

static int stripModifiers(int modifierFlags)
{
	return modifierFlags & ~(NSShiftKeyMask | NSAlternateKeyMask);
}

static SEL getSelector(unichar charcode, int modifierFlags)
{
	NSString* keyString = toSelectorString(charcode, modifierFlags);
	SEL selector = NSSelectorFromString([keyString stringByAppendingString:@":"]);
	return selector;
}

static SEL matchSingleHandler(id target, unichar charcode, int modifierFlags)
{
	SEL selector = getSelector(charcode, modifierFlags);
	BOOL responds = [target respondsToSelector:selector];
	return responds ? selector : NULL;
}

- (SEL) selectorForInstance:(id)target {
	SEL handler = NULL;
	
	handler = handler ? handler : matchSingleHandler(target, self.key, self.modifierFlags);
	handler = handler ? handler : matchSingleHandler(target, self.key, stripModifiers(self.modifierFlags));
		
	return handler;
}

- (XVimKeyStroke*)keyStrokeByStrippingModifiers
{
	XVimKeyStroke* newKeyStroke = [[XVimKeyStroke alloc] init];
	newKeyStroke.key = self.key;
	newKeyStroke.modifierFlags = stripModifiers(self.modifierFlags);
	return newKeyStroke;
}

- (BOOL)instanceResponds:(id)target
{
	return [self selectorForInstance:target] != NULL;
}

- (BOOL)classResponds:(Class)class
{
	return [class instancesRespondToSelector:getSelector(self.key, self.modifierFlags)] || 
	[class instancesRespondToSelector:getSelector(self.key, stripModifiers(self.modifierFlags))];
}

+ (XVimKeyStroke *)fromString:(NSString *)string from:(NSUInteger*)index
{
	NSUInteger starti = *index;
	NSUInteger endi = starti;
	NSString *keyString = NULL;
	
	int modifierFlags = 0;
	if ([string characterAtIndex:starti] == '<')
	{
		// Find modifier flags, if any
		{
			NSString *uppercaseString = [[string substringFromIndex:starti+1] uppercaseString];
			
			if ([uppercaseString hasPrefix:@"S-"])
			{
				modifierFlags = NSShiftKeyMask;
			}
			if ([uppercaseString hasPrefix:@"C-"])
			{
				modifierFlags = NSControlKeyMask;
			}
			if ([uppercaseString hasPrefix:@"M-"])
			{
				modifierFlags = NSAlternateKeyMask;
			}
			if ([uppercaseString hasPrefix:@"D-"])
			{
				modifierFlags = NSCommandKeyMask;
			}
		}
		
		NSRange searchRange = {starti, string.length - starti};
		NSRange keyStringEndRange = [string rangeOfString:@">" options:0 range:searchRange];
		
		NSUInteger keyStringStarti = starti + 1 + (modifierFlags ? 2 : 0);
		NSUInteger keyStringEndi = keyStringEndRange.location;
		
		endi = keyStringEndi + 1; // Skip > char
		
		NSRange keyStringRange = {keyStringStarti, keyStringEndi - keyStringStarti};
		keyString = [string substringWithRange:keyStringRange];
	} else {
		endi = starti + 1;
		
		NSRange keyStringRange = {starti, endi - starti};
		keyString = [string substringWithRange:keyStringRange];
	}
	
	NSNumber *number = NULL;
	number = number ? number : [s_stringToKeyCode objectForKey:keyString];
	number = number ? number : [s_stringToKeyCode objectForKey:[keyString uppercaseString]];
	
	XVimKeyStroke *keyStroke = NULL;
	if (number)
	{
		keyStroke = [[XVimKeyStroke alloc] init];
		keyStroke.key = [number intValue];
		keyStroke.modifierFlags = modifierFlags;
	}
	
	*index = endi;
	return keyStroke;
}

+ (XVimKeyStroke*)fromString:(NSString *)string
{
	NSUInteger index = 0;
	XVimKeyStroke *keyStroke = [self fromString:string from:&index];
	return keyStroke;
}

+ (void)fromString:(NSString *)string to:(NSMutableArray *)keystrokes
{
	NSUInteger index = 0;
	NSUInteger len = string.length;
	while (index < len)
	{
		XVimKeyStroke* keyStroke = [self fromString:string from:&index];
		if (keyStroke == NULL) { break; }
		[keystrokes addObject:keyStroke];
	}
}

@end