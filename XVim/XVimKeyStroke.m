//
//  XVimKeyStroke.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeyStroke.h"
#import "NSEvent+VimHelper.h"

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
    "DEL",
    "HOME",
    "END",
    "PAGEUP",
    "PAGEDOWN"
};

static char* readable_keynames[] = {
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
    "!",
    "\"",
    "#",
    "$",
    "%",
    "&",
    "'",
    "(",
    ")",
    "*",
    "+",
    ",",
    "-",
    ".",
    "/",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    ":",
    ";",
    "<",
    "=",
    ">",
    "?",
    "@",
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
    "[",
    "\\",
    "]",
    "^",
    "_",
    "`",
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
    "{", // {
    "|", // |
    "}", // }
    "~", // ~
    "DEL",
    "HOME",
    "END",
    "PAGEUP",
    "PAGEDOWN"
};
static NSMutableDictionary *s_keyCodeToSelectorString = NULL;
static NSMutableDictionary *s_stringToKeyCode = NULL;

@interface XVimKeyStroke()
@property (strong, nonatomic) NSEvent *event;
@end

@implementation XVimKeyStroke
@synthesize event = _event;
@synthesize keyCode = _keyCode;
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
		map(@"ForwardDelete", 63272);
        map(@"Home", 63273);
        map(@"End", 63275);
        map(@"Pageup", 63276);
        map(@"Pagedown", 63277);
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
		map(@"FORWARD_DELETE", 63272);
        map(@"HOME", 63273);
        map(@"END", 63275);
        map(@"PAGEUP", 63276);
        map(@"PAGEDOWN", 63277);
		
		// From space to del (non-inclusive), add ascii names
		for (int i = 32; i < 127; ++i)
		{
			unichar c = i;
			NSString *string = [NSString stringWithCharacters:&c length:1];
			map(string, i);
		}

        // Map the last key - "DEL"
        NSString *string = [NSString stringWithCString:keynames[127] encoding:NSASCIIStringEncoding];
        map([string uppercaseString], 127);
	}
}

+ (void)initKeymaps
{
	[self initKeyCodeToSelectorString];
	[self initStringToKeyCode];
}

- (NSUInteger)hash
{
	return self.modifierFlags + self.keyCode;
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
	return self.keyCode == other.keyCode && self.modifierFlags == other.modifierFlags;
}

- (id)copyWithZone:(NSZone *)zone {
	XVimKeyStroke* copy = [[XVimKeyStroke allocWithZone:zone] init];
	copy.event = self.event;
	copy.keyCode = self.keyCode;
	copy.modifierFlags = self.modifierFlags;
	return copy;
}

+ (XVimKeyStroke*)keyStrokeOptionsFromEvent:(NSEvent*)event into:(NSMutableArray*)options
{
	XVimKeyStroke *primaryKeyStroke = nil;
	NSUInteger modifierFlags = event.modifierFlags & (NSShiftKeyMask | NSAlternateKeyMask | NSControlKeyMask | NSCommandKeyMask);
	
    unichar unmodifiedKeyCode = [event unmodifiedKeyCode];
    unichar modifiedKeyCode = [event modifiedKeyCode];
	
	if (modifierFlags & (NSControlKeyMask | NSCommandKeyMask))
	{
		// Eg. "C-a"
		XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithEvent:event
																keyCode:unmodifiedKeyCode
														  modifierFlags:modifierFlags];
		
		[options addObject:keyStroke];
		primaryKeyStroke = keyStroke;
	}
	else if (modifierFlags & (NSShiftKeyMask | NSAlternateKeyMask))
	{
		// Eg. "S-a"
		{
			XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithEvent:event
																	keyCode:unmodifiedKeyCode
															  modifierFlags:modifierFlags];
			[options addObject:keyStroke];
		}
		
		// Eg. "S-A"
		{
			XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithEvent:event
																	keyCode:modifiedKeyCode
															  modifierFlags:modifierFlags];
			[options addObject:keyStroke];
		}
		
		// Eg. "A"
		{
			XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithEvent:event
																	keyCode:modifiedKeyCode
															  modifierFlags:0];
			[options addObject:keyStroke];
			primaryKeyStroke = keyStroke;
		}
	}
	else
	{
		XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithEvent:event
																keyCode:modifiedKeyCode
														  modifierFlags:0];
		
		[options addObject:keyStroke];
		primaryKeyStroke = keyStroke;
	}
	
	return primaryKeyStroke;
}

- (id)initWithKeyCode:(unichar)keyCode
		modifierFlags:(NSUInteger)modifierFlags
{
	if (self = [super init])
	{
		self->_keyCode = keyCode;
		self->_modifierFlags = modifierFlags;
	}
	return self;
}

// Constructs a key stroke from an event
- (id)initWithEvent:(NSEvent*)event 
				keyCode:(unichar)keyCode 
		  modifierFlags:(NSUInteger)modifierFlags
{
	if (self = [self initWithKeyCode:keyCode modifierFlags:modifierFlags])
	{
		self->_event = event;
	}
	return self;
}

- (NSEvent*)toEvent
{
	NSEvent *event = _event;
	
	// This key stroke is from a key map, synthesise event
	if (!event)
	{
		unichar c = self.keyCode;
		NSString *characters = [NSString stringWithCharacters:&c length:1];
		NSUInteger mflags = self.modifierFlags;
		
		event = [NSEvent keyEventWithType:NSKeyDown 
								 location:NSMakePoint(0, 0)
							modifierFlags:mflags
								timestamp:0
							 windowNumber:0
								  context:nil
							   characters:characters
			  charactersIgnoringModifiers:characters
								isARepeat:NO 
								  keyCode:0];
	}
	
	return event;
}

static NSString* toSelectorString(unichar charcode, NSUInteger modifierFlags)
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

- (NSString*) toString 
{
	unichar charcode = self.keyCode;
	NSUInteger modifierFlags = self.modifierFlags;
	
	NSMutableString* keyStr = [[[NSMutableString alloc] init] autorelease];
	if( modifierFlags & NSControlKeyMask ){
		[keyStr appendString:@"C-"];
	}
	if( modifierFlags & NSAlternateKeyMask ){
		[keyStr appendString:@"M-"];
	}
	if( modifierFlags & NSCommandKeyMask ){
		[keyStr appendString:@"D-"];
	}
	
	if (charcode <= 127)
	{
		NSString *keyname = [NSString stringWithCString:readable_keynames[charcode] encoding:NSASCIIStringEncoding];
		if (keyname) { 
			[keyStr appendString:keyname];
		}
	}
	
	return keyStr;
}

- (NSString*) toSelectorString {
	return toSelectorString(self.keyCode, self.modifierFlags);
}

- (NSString*)description {
	return [self toString];
}

static SEL getSelector(unichar charcode, NSUInteger modifierFlags)
{
	NSString* keyString = toSelectorString(charcode, modifierFlags);
	SEL selector = NSSelectorFromString([keyString stringByAppendingString:@":"]);
	return selector;
}

- (SEL)selector {
	return getSelector(self.keyCode, self.modifierFlags);
}

- (SEL)selectorForInstance:(id)target {
	SEL selector = getSelector(self.keyCode, self.modifierFlags);
	BOOL responds = [target respondsToSelector:selector];
	return responds ? selector : NULL;
}

- (BOOL)instanceResponds:(id)target
{
	return [self selectorForInstance:target] != NULL;
}

- (BOOL)classResponds:(Class)class
{
	SEL selector = [self selector];
	return [class instancesRespondToSelector:selector];
}

- (BOOL)classImplements:(Class)class
{
	SEL selector = [self selector];
	IMP imp = [class instanceMethodForSelector:selector];
	return imp && imp != [[class superclass] instanceMethodForSelector:selector];
}

+ (XVimKeyStroke *)fromString:(NSString *)string from:(NSUInteger*)index
{
	NSUInteger starti = *index;
	NSUInteger endi = starti;
	NSString *keyString = NULL;
	
	NSUInteger modifierFlags = 0;
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
		keyStroke = [[XVimKeyStroke alloc] initWithKeyCode:[number intValue]
											 modifierFlags:modifierFlags];
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