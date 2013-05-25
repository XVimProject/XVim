//
//  XVimKeyStroke.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeyStroke.h"
#import "NSEvent+VimHelper.h"

struct key_map{
    NSString* key;
    unichar c;
    NSString* selector;
};

static struct key_map key_maps[] = {
    {@"NUL", 0, @"NUL"},
    {@"SOH", 1, @"SOH"},
    {@"STX", 2, @"STX"},
    {@"ETX", 3, @"ETX" },
    {@"EOT", 4, @"EOT"},
    {@"ENQ", 5, @"ENQ"},
    {@"ACK", 6, @"ACK"},
    {@"BEL", 7, @"BEL"},
    {@"BS",  8, @"BS" },
    {@"HT",  9, @"TAB"},
    {@"TAB", 9, @"TAB"},
    {@"NL",  10, @"NL"},
    {@"VT",  11, @"VT"},
    {@"NP",  12, @"NP"},
    {@"CR",  13, @"CR"},
    {@"RETURN", 13, @"CR"},
    {@"ENTER", 13, @"CR"},
    {@"SO",  14, @"SO"},
    {@"SI",  15, @"SI"},
    {@"DLE", 16, @"DLE"},
    {@"DC1", 17, @"DC1"},
    {@"DC2", 18, @"DC2"},
    {@"DC3", 19, @"DC3"},
    {@"DC4", 20, @"DC4"},
    {@"NAK", 21, @"NAK"},
    {@"SYN", 22, @"SYN"},
    {@"ETB", 23, @"ETB"},
    {@"CAN", 24, @"CAN"},
    {@"EM",  25, @"EM"},
    {@"SUB", 26, @"SUB"},
    {@"ESC", 27, @"ESC"},
    {@"FS",  28, @"FS"},
    {@"GS",  29, @"GS"},
    {@"RS",  30, @"RS"},
    {@"US",  31, @"US"},
    {@"SPACE", 32, @"SPACE"},
    {@"!", 33, @"EXCLAMATION"},
    {@"\"", 34, @"DQUOTE"},
    {@"#", 35, @"NUMBER"},
    {@"$", 36, @"DOLLER"},
    {@"%", 37, @"PERCENT"},
    {@"&", 38, @"AMPASAND"},
    {@"'", 39, @"SQUOTE"},
    {@"(", 40, @"LPARENTHESIS"},
    {@")", 41, @"RPARENTHESIS"},
    {@"*", 42, @"ASTERISC"},
    {@"+", 43, @"PLUS"},
    {@",", 44, @"COMMA"},
    {@"-", 45, @"MINUS"},
    {@".", 46, @"DOT"},
    {@"/", 47, @"SLASH"},
    {@"0", 48, @"NUM0"},
    {@"1", 49, @"NUM1"},
    {@"2", 50, @"NUM2"},
    {@"3", 51, @"NUM3"},
    {@"4", 52, @"NUM4"},
    {@"5", 53, @"NUM5"},
    {@"6", 54, @"NUM6"},
    {@"7", 55, @"NUM7"},
    {@"8", 56, @"NUM8"},
    {@"9", 57, @"NUM9"},
    {@":", 58, @"COLON"},
    {@";", 59, @"SEMICOLON"},
    {@"<", 60, @"LESSTAHN"},
    {@"lt",60, @"LESSTHAN"},
    {@"=", 61, @"EQUAL"},
    {@">", 62, @"GREATERTHAN"},
    {@"?", 63, @"QUESTION"},
    {@"@", 64, @"AT"},
    {@"A", 65, @"A" },
    {@"B", 66, @"B"},
    {@"C", 67, @"C"},
    {@"D", 68, @"D"},
    {@"E", 69, @"E"},
    {@"F", 70, @"F"},
    {@"G", 71, @"G"},
    {@"H", 72, @"H"},
    {@"I", 73, @"I"},
    {@"J", 74, @"J"},
    {@"K", 75, @"K"},
    {@"L", 76, @"L"},
    {@"M", 77, @"M"},
    {@"N", 78, @"N"},
    {@"O", 79, @"O"},
    {@"P", 80, @"P"},
    {@"Q", 81, @"Q"},
    {@"R", 82, @"R"},
    {@"S", 83, @"S"},
    {@"T", 84, @"T"},
    {@"U", 85, @"U"},
    {@"V", 86, @"V"},
    {@"W", 87, @"W"},
    {@"X", 88, @"X"},
    {@"Y", 89, @"Y"},
    {@"Z", 90, @"Z"},
    {@"[", 91, @"LSQUAREBLAKET"},
    {@"\\",92, @"BACKSLASH"},
    {@"BSLASH", 92, @"BACKSLASH"},
    {@"]",93, @"RSQUAREBLACKET"},
    {@"^",94, @"HAT"},
    {@"_",95, @"UNDERSCORE"},
    {@"`",96, @"BACKQUOTE"},
    {@"a",97, @"a"},
    {@"b",98, @"b"},
    {@"c",99, @"c"},
    {@"d",100, @"d"},
    {@"e",101, @"e"},
    {@"f",102, @"f"},
    {@"g",103, @"g"},
    {@"h",104, @"h"},
    {@"i",105, @"i"},
    {@"j",106, @"j"},
    {@"k",107, @"k"},
    {@"l",108, @"l"},
    {@"m",109, @"m"},
    {@"n",110, @"n"},
    {@"o",111, @"o"},
    {@"p",112, @"p"},
    {@"q",113, @"q"},
    {@"r",114, @"r"},
    {@"s",115, @"s"},
    {@"t",116, @"t"},
    {@"u",117, @"u"},
    {@"v",118, @"v"},
    {@"w",119, @"w"},
    {@"x",120, @"x"},
    {@"y",121, @"y"},
    {@"z",122, @"z"},
    {@"{",123, @"LBRACE"},
    {@"|",124, @"BAR"},
    {@"BAR",124, @"BAR"},
    {@"}",125, @"RBRACE"},
    {@"~",126, @"TILDE"},
    {@"DEL",127, @"DEL"},
    {@"UP",63232, @"UP"},
    {@"DOWN", 63233, @"DOWN"},
    {@"LEFT", 63234, @"LEFT"},
    {@"RIGHT", 63235, @"RIGHT"},
    {@"F1", 63236, @"F1"},
    {@"F2", 63237, @"F2"},
    {@"F3", 63238, @"F3"},
    {@"F4", 63239, @"F4"},
    {@"F5", 63240, @"F5"},
    {@"F6", 63241, @"F6"},
    {@"F7", 63242, @"F7"},
    {@"F8", 63243, @"F8"},
    {@"F9", 63244, @"F9"},
    {@"F10", 63245, @"F10"},
    {@"F11", 63246, @"F11"},
    {@"F12", 63247, @"F12"},
    {@"FORWARD_DELETE", 63272, @"FORWARD_DELETE"},
    {@"HOME", 63273, @"HOME"},
    {@"END", 63275, @"END"},
    {@"PAGEUP", 63276, @"PAGEUP"},
    {@"PAGEDOWN", 63277, @"PAGEDOWN"}
};

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

static NSMutableDictionary *s_unicharToSelector = nil;
static NSMutableDictionary *s_keyToUnichar = nil;
static NSMutableDictionary *s_keyCodeToSelectorString = nil;
static NSMutableDictionary *s_stringToKeyCode = NULL;

@interface XVimKeyStroke()
@property (strong, nonatomic) NSEvent *event;
@end

@implementation XVimKeyStroke
@synthesize event = _event;
@synthesize keyCode = _keyCode;
@synthesize modifierFlags = _modifierFlags;

+ (void)initUnicharToSelector{
    if( nil == s_unicharToSelector ){
        s_unicharToSelector = [[NSMutableDictionary alloc] init]; // Never release
        for( unsigned int i = 0; i < sizeof(key_maps)/sizeof(struct key_map); i++ ){
            [s_unicharToSelector setObject:key_maps[i].selector forKey:[NSNumber numberWithUnsignedInteger:key_maps[i].c]];
        }
    }
}

+ (void)initKeyToUnichar{
    if( nil == s_keyToUnichar){
        s_keyToUnichar = [[NSMutableDictionary alloc] init]; // Never release
        for( unsigned int i = 0; i < sizeof(key_maps)/sizeof(struct key_map); i++ ){
            [s_keyToUnichar setObject:[NSNumber numberWithUnsignedInteger:key_maps[i].c] forKey:key_maps[i].key];
        }
    }
}

+ (NSString*)selectorFromUnichar:(unichar)c{
    if( nil == s_unicharToSelector ){
        [self initUnicharToSelector];
    }
    return [s_unicharToSelector objectForKey:[NSNumber numberWithUnsignedInteger:c]];
}

+ (unichar)unicharFromKey:(NSString*)key{
    if( nil == s_keyToUnichar ){
        [self initKeyToUnichar];
    }
    
    if( ![self isValidKey:key] ){
        return (unichar)-1;
    }else{
        if( [key length] > 1){
            key = [key uppercaseString];
        }
        return [[s_keyToUnichar objectForKey:key] unsignedIntegerValue];
    }
}

+ (BOOL)isValidKey:(NSString*)key{
    if( nil == s_keyToUnichar ){
        [self initKeyToUnichar];
    }
    // Notations like <CR>, <SPACE> are all case insensitive
    if( [key length] > 1 ){
        key = [key uppercaseString];
    }
    return nil != [s_keyToUnichar objectForKey:key];
}

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
            [keyStroke release];
		}
		
		// Eg. "S-A"
		{
			XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithEvent:event
																	keyCode:modifiedKeyCode
															  modifierFlags:modifierFlags];
			[options addObject:keyStroke];
            [keyStroke release];
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
	
	return [primaryKeyStroke autorelease];
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

- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(NSGraphicsContext*)context;
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
							 windowNumber:num
								  context:context
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

static SEL getSelector(unichar charcode, NSUInteger modifierFlags) {
	NSString* keyString = toSelectorString(charcode, modifierFlags);
	SEL selector = NSSelectorFromString([keyString stringByAppendingString:@""]);
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

+ (XVimKeyStroke *)fromString:(NSString *)string from:(NSUInteger*)index{
	NSUInteger starti = *index;
	
	NSUInteger modifierFlags = 0;
    NSUInteger p = starti;
    NSUInteger length = [string length];
	if ([string characterAtIndex:starti] == '<') {
		// Find modifier flags, if any
        p += 1; // skip first '<' letter
        NSRange keyEnd = [string rangeOfString:@">" options:0 range:NSMakeRange(p, length-p)];
        if( keyEnd.location != NSNotFound ){
            while(1){
                NSString *uppercaseString = [[string substringFromIndex:p] uppercaseString];
                if ([uppercaseString hasPrefix:@"S-"]){
                    modifierFlags |= NSShiftKeyMask;
                }
                else if ([uppercaseString hasPrefix:@"C-"]) {
                    modifierFlags |= NSControlKeyMask;
                }
                else if ([uppercaseString hasPrefix:@"M-"]) {
                    modifierFlags |= NSAlternateKeyMask;
                }
                else if ([uppercaseString hasPrefix:@"D-"]) {
                    modifierFlags |= NSCommandKeyMask;
                }else{
                    break;
                }
                p+=2;
            }
        
            NSString* key = [string substringWithRange:NSMakeRange(p, keyEnd.location-p)];
            if( [self isValidKey:key] ){
                if( 0 == modifierFlags ){
                    //If it does not have modifier flag the key must be multiple letters
                    if( [key length] > 1 ){
                        *index = keyEnd.location+1;
                        unichar c = [self unicharFromKey:key];
                        return [[[XVimKeyStroke alloc] initWithKeyCode:c modifierFlags:modifierFlags] autorelease];
                    }
                }else{
                    //This is modifier flag + valid key
                    *index = keyEnd.location+1;
                    unichar c = [self unicharFromKey:key];
                    return [[[XVimKeyStroke alloc] initWithKeyCode:c modifierFlags:modifierFlags] autorelease];
                }
            }
        }
        // if it not valid key like "<a>" or "<c>" take first letter "<" as a key
        // Just go through.
    }
    
    // Simple one letter key
    NSString* key = [string substringWithRange:NSMakeRange(starti, 1)];
    unichar c = [self unicharFromKey:key];
    *index = starti+1;
    return [[[XVimKeyStroke alloc] initWithKeyCode:c modifierFlags:modifierFlags] autorelease];
}

+ (XVimKeyStroke*)fromString:(NSString *)string {
	NSUInteger index = 0;
	XVimKeyStroke *keyStroke = [self fromString:string from:&index];
	return keyStroke;
}

+ (NSArray*)keyStrokesfromString:(NSString *)string {
	NSUInteger index = 0;
	NSUInteger len = string.length;
    NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	while (index < len){
		XVimKeyStroke* keyStroke = [self fromString:string from:&index];
		if (keyStroke == NULL) { break; }
		[array addObject:keyStroke];
	}
    return array;
}

@end