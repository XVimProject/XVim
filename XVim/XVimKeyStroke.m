//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimKeyStroke.h"
#import "NSEvent+VimHelper.h"
#import "Logger.h"

/*
 // Vim key handling (maybe correct) //
 // keymap.h file in Vim source helps understand this better //
 In Vim they treat all the input as a character.
 This is how recordings or keymapping does work.
 Vim uses internal code(character) to express an input(usually a key stroke).
 For example if it is key stroke 'a' internal expression is just ascii 'a'.
 If the key is special like backspace internal expression is 0x80, 'k', 'b' (3byte).
 Vim uses 0x80 as a escape character and followng bytes defines the key.
 Special keys like F1-F10 or S-F1 are all mapped to a 0x80 prefixed value.
 
 Vim always does following convertings.
 [Phisical Key Input] -> [Vim intarnal code]
 [Key Notation in key map] -> [Vim internal code]
 
 And Vim interprets the [Vim intarnal code] as input and takes action.
 Printable codes are all stayed same.
 So if you record 'iabc<BS>' the internal code in Vim is 'iabc0x80kb'.
 You can see this when you see the recorded register with :registers
 
 If the key stroke has modifier Vim uses additional byte to represent the modifiers.
 For example for Alt-F2 Vim internal code is like 
 0x80,0xfc(252),0x08,0x80,k,2   where
    - 0x80,0xfc(252) means it has modifier flag and
    - 0x08 means the modifier is Alt
    - 0x80,k,2 is internal code for F2
 
 As Vim does XVim have internal code.
 XVim follows Vim way but the values we use is different. And also we use 
 unichar(2bytes) instead of char in Vim
 This means...
   - Character betwee 0xF800 to 0xF8FF describes modifier flags with lower byte
     (The range 0xF800-0xF8FF is private area in unicode and NSEvent does not use this range so far)
   - For special keys like F1, arrow keys XVim does not use the same code with Vim.
     Cocoa defines unichar value for them so we use it instead.
     See http://cocoadev.com/wiki/KeyBindings or AppKit/NSEvent.h file
 
 So normal keys like 'a' is just 0x0061 but 'Alt+a' will be 0xF808,0x0061 (4bytes) where 0xF808 represents Alt.
 
 Note that all the key sequences are represented as array of unichar which is 2byte.
 You have to be careful about endian.
 So the value 'Alt+a' will be 0x08 0xF8 0x61 0x00 in byte sequence(each unichar endian is little endian)
 This makes easy to handle key sequence as NSString.
 
 I call this internal expression "XVimString"
 */


/* 
Following bit mask for modifiers is from NSEvent.h
We do not use this mask because modifier mask must be fits in 1 byte length.
 
enum {
    NSAlphaShiftKeyMask         = 1 << 16,
    NSShiftKeyMask              = 1 << 17,
    NSControlKeyMask            = 1 << 18,
    NSAlternateKeyMask          = 1 << 19,
    NSCommandKeyMask            = 1 << 20,
    NSNumericPadKeyMask         = 1 << 21,
    NSHelpKeyMask               = 1 << 22,
    NSFunctionKeyMask           = 1 << 23,
    NSDeviceIndependentModifierFlagsMask    = 0xffff0000UL
};
 */

#define KS_MODIFIER         0xF8  // This value is not the same as Vim's one
// These values are differed from Vim's definition in keymap.h
#define XVIM_MOD_SHIFT      0x02  //  1 << 1
#define XVIM_MOD_CTRL       0x04  //  1 << 2
#define XVIM_MOD_ALT        0x08  //  1 << 3
#define XVIM_MOD_CMD        0x10  //  1 << 4
#define XVIM_MOD_FUNC       0x80  //  1 << 7

#define XVIM_MODIFIER_MASK  0x9E  // Mask for used bits. (Change if you add some MOD_MASK_XXX)
#define XVIM_MODIFIER_MIN   0xF802
#define XVIM_MODIFIER_MAX   0xF880

#define NSMOD2XVIMMOD(x) ((unsigned int)x >> 16)
#define XVIMMOD2NSMOD(x) ((unsigned int)x << 16)
#define XVIM_MAKE_MODIFIER(x) ((unsigned short)((KS_MODIFIER<<8) | x ))   // Crate 0xF8XX

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
    {@"$", 36, @"DOLLAR"},
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
    {@"[", 91, @"LSQUAREBRACKET"},
    {@"\\",92, @"BACKSLASH"},
    {@"BSLASH", 92, @"BACKSLASH"},
    {@"]",93, @"RSQUAREBRACKET"},
    {@"^",94, @"CARET"},
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

static NSMutableDictionary *s_unicharToSelector = nil;
static NSMutableDictionary *s_keyToUnichar = nil;

static BOOL isPrintable(unichar c){
    // FIXME:
    // There may be better difinition of printable characters in unicode
    if( c < 32 || c == 127 || ( 63232 <= c && c <= 63277 ) ){
        return NO;
    }
    return YES;
}

static BOOL isModifier(unichar c){
    return ( XVIM_MODIFIER_MIN <= c && c <= XVIM_MODIFIER_MAX );
}

@implementation NSString(XVimKeyStroke)
- (NSArray*)toKeyStrokes{
    NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
    for( NSUInteger i = 0; i < self.length; i++ ){
        unichar c1 = [self characterAtIndex:i];
        unichar c2;
        if( isModifier( c1 ) ){
            i++;
            c2 = [self characterAtIndex:i];
        }else{
            c2 = c1;
            c1 = 0;
        }
        
        XVimKeyStroke* stroke = [[[XVimKeyStroke alloc] initWithCharacter:c2 modifier:c1] autorelease];
        [array addObject:stroke];
    }
    return array;
}
@end


@implementation XVimKeyStroke

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

- (id)initWithCharacter:(unichar)c modifier:(unsigned char)mod{
    if( self = [super init] ){
        self.character = c;
        self.modifier = mod;
    }
    return self;
}

+ (NSString*) eventToXVimString:(NSEvent*)event{
    NSAssert( event.type == NSKeyDown , @"Event type must be NSKeyDown");
    NSAssert( event.charactersIgnoringModifiers.length != 0, @"Event does not contain any character");
    
    unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
    unsigned char mod = NSMOD2XVIMMOD(event.modifierFlags);
    return [[[[XVimKeyStroke alloc] initWithCharacter:c modifier:mod] autorelease] xvimString];
    
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

+ (XVimKeyStroke*)keyStrokeOptionsFromEvent:(NSEvent*)event into:(NSMutableArray*)options{
	XVimKeyStroke *primaryKeyStroke = nil;
	NSUInteger modifierFlags = NSMOD2XVIMMOD(event.modifierFlags);
	
    unichar unmodifiedKeyCode = [event unmodifiedKeyCode];
    unichar modifiedKeyCode = [event modifiedKeyCode];

    
	if (modifierFlags & (XVIM_MOD_CTRL| XVIM_MOD_CMD)){
		// Eg. "C-a"
		XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithCharacter:unmodifiedKeyCode modifier:modifierFlags];
		[options addObject:keyStroke];
		primaryKeyStroke = keyStroke;
	}
	else if (modifierFlags & (XVIM_MOD_SHIFT| XVIM_MOD_ALT)) {
        // When 'a'  unmodified and modified key code in NSEvent is 97(='a') and no modifier flag is on.
        // When Shift-a which results in a letter 'A'  unmodified and modified key code are both 65(='A') and Shift modifier flag is on.
		// Eg. "S-a"
		{
			XVimKeyStroke *keyStroke = [[[XVimKeyStroke alloc] initWithCharacter:unmodifiedKeyCode modifier:modifierFlags] autorelease];
			[options addObject:keyStroke];
		}
		
		// Eg. "S-A"
		{
			XVimKeyStroke *keyStroke = [[[XVimKeyStroke alloc] initWithCharacter:unmodifiedKeyCode modifier:modifierFlags] autorelease];
			[options addObject:keyStroke];
		}
		
		// Eg. "A"
		{
			XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithCharacter:modifiedKeyCode modifier:0];
			[options addObject:keyStroke];
			primaryKeyStroke = keyStroke;
		}
	}
	else {
		XVimKeyStroke *keyStroke = [[XVimKeyStroke alloc] initWithCharacter:modifiedKeyCode modifier:0];
		[options addObject:keyStroke];
		primaryKeyStroke = keyStroke;
	}
	
	return [primaryKeyStroke autorelease];
}

+ (XVimString*)keyStrokesToXVimString:(NSArray*)strokes{
    NSMutableString* str = [[[NSMutableString alloc] init] autorelease];
    for( XVimKeyStroke* stroke in strokes ){
        [str appendString:[stroke xvimString]];
    }
    return str;
}

+ (XVimKeyStroke *)fromNotation:(NSString *)string from:(NSUInteger*)index{
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
                    modifierFlags |= XVIM_MOD_SHIFT;
                }
                else if ([uppercaseString hasPrefix:@"C-"]) {
                    modifierFlags |= XVIM_MOD_CTRL;
                }
                else if ([uppercaseString hasPrefix:@"M-"]) {
                    modifierFlags |= XVIM_MOD_ALT;
                }
                else if ([uppercaseString hasPrefix:@"A-"]) {
                    modifierFlags |= XVIM_MOD_ALT;
                }
                else if ([uppercaseString hasPrefix:@"D-"]) {
                    modifierFlags |= XVIM_MOD_CMD;
                }
                else if ([uppercaseString hasPrefix:@"F-"]) {
                    modifierFlags |= XVIM_MOD_FUNC;
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
                        return [[[XVimKeyStroke alloc] initWithCharacter:c modifier:modifierFlags] autorelease];
                    }
                }else{
                    //This is modifier flag + valid key
                    *index = keyEnd.location+1;
                    unichar c = [self unicharFromKey:key];
                    return [[[XVimKeyStroke alloc] initWithCharacter:c modifier:modifierFlags] autorelease];
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
    return [[[XVimKeyStroke alloc] initWithCharacter:c modifier:modifierFlags] autorelease];
}

+ (XVimKeyStroke*)fromXVimString:(NSString *)string {
	NSUInteger index = 0;
	XVimKeyStroke *keyStroke = [self fromNotation:string from:&index];
	return keyStroke;
}

+ (XVimString*)xvimStringFromKeyNotation:(NSString*)notation{
    NSArray* array = [XVimKeyStroke keyStrokesfromNotation:notation];
    return [XVimKeyStroke keyStrokesToXVimString:array];
}

+ (NSArray*)keyStrokesfromNotation:(NSString *)notation{
	NSUInteger index = 0;
	NSUInteger len = notation.length;
    NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	while (index < len){
		XVimKeyStroke* keyStroke = [self fromNotation:notation from:&index];
		if (keyStroke == NULL) { break; }
		[array addObject:keyStroke];
	}
    return array;
}


- (XVimString*)xvimString{
    NSMutableString* str = [[[NSMutableString alloc] init] autorelease];
    // If the character is pritable we do not consider Shift modifier
    // For example <S-!> and ! is same
    if( isPrintable(self.character) ){
        self.modifier = self.modifier & ~XVIM_MOD_SHIFT;
    }
    if( self.modifier != 0 ){
        [str appendFormat:@"%C", XVIM_MAKE_MODIFIER(self.modifier)];
    }
    [str appendFormat:@"%C", self.character];
    return str;
}

- (BOOL) isNumeric{
    NSString *keyStr = [self toSelectorString];
    return [keyStr hasPrefix:@"NUM"] && [keyStr length] == 4;
}

- (NSUInteger)hash{
    // FIXME: This is not valid
	return self.modifier + self.character;
}

- (BOOL)isEqual:(id)object{
	if (object == self) {
		return YES;
	}	
	if (!object || ![object isKindOfClass:[self class]]){
		return NO;
	}
	XVimKeyStroke* other = object;
	return self.character == other.character && self.modifier== other.modifier;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[XVimKeyStroke allocWithZone:zone] initWithCharacter:self.character modifier:self.modifier];
}

- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(NSGraphicsContext*)context; {
    unichar c = self.character;
    NSString *characters = [NSString stringWithCharacters:&c length:1];
    NSUInteger mflags = XVIMMOD2NSMOD(self.modifier);
    
    return  [NSEvent keyEventWithType:NSKeyDown
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


- (NSString*)description{
    NSMutableString* str = [[[NSMutableString alloc] init] autorelease];
    if( 0 != self.modifier){
        unichar m = XVIM_MAKE_MODIFIER(self.modifier);
        [str appendFormat:@"0x%02x 0x%02x ", ((unsigned char*)(&m))[1], ((unsigned char*)(&m))[0]];
    }
    unichar c = self.character;
    if( isPrintable(c)){
        [str appendFormat:@"%C", c];
    }else{
        [str appendFormat:@"0x%02x 0x%02x", ((unsigned char*)(&c))[1], ((unsigned char*)(&c))[0]];
    }
    return str;
}

/*
- (NSString*)notation{
	unichar charcode = self.character;
	NSUInteger modifierFlags = XVIMMOD2NSMOD(self.modifier);
	
	NSMutableString* keyStr = [[[NSMutableString alloc] init] autorelease];
	if( self.modifier & XVIM_MOD_CTRL){
		[keyStr appendString:@"C-"];
	}
	if( self.modifier & XVIM_MOD_ALT){
		[keyStr appendString:@"M-"];
	}
	if( self.modifier & XVIM_MOD_CMD){
		[keyStr appendString:@"D-"];
	}
	if( self.modifier & XVIM_MOD_FUNC){
		[keyStr appendString:@"F-"];
	}
	
	if (isPrintable(charcode)) {
        
		if (keyname) { 
			[keyStr appendString:keyname];
		}
	}else{
        
    }
	
	return keyStr;
}
 */

- (NSString*) toSelectorString {
	// S- Shift
	// C- Control
	// M- Option
	// D- Command
    // F_ Function (not F1,F2.. but 'Function' key)
	NSMutableString* keyStr = [[[NSMutableString alloc] init] autorelease];
	if( self.modifier & XVIM_MOD_SHIFT){
		[keyStr appendString:@"S_"];
	}
	if( self.modifier & XVIM_MOD_CTRL){
		[keyStr appendString:@"C_"];
	}
	if( self.modifier & XVIM_MOD_ALT){
		[keyStr appendString:@"M_"];
	}
	if( self.modifier & XVIM_MOD_CMD){
		[keyStr appendString:@"D_"];
	}
    if( self.modifier & XVIM_MOD_FUNC){
        [keyStr appendString:@"F_"];
    }
	
	NSString *keyname = [XVimKeyStroke selectorFromUnichar:self.character];
	if (keyname) { 
		[keyStr appendString:keyname];
	}
	
	return keyStr;
}

- (SEL)selector {
    return NSSelectorFromString([self toSelectorString]);
}

- (SEL)selectorForInstance:(id)target {
	if( [target respondsToSelector:self.selector] ){
        return self.selector;
    }else{
        return nil;
    }
}

- (BOOL)instanceResponds:(id)target {
	return [self selectorForInstance:target] != nil;
}

- (BOOL)classResponds:(Class)class{
	return [class instancesRespondToSelector:self.selector];
}

- (BOOL)classImplements:(Class)class {
	IMP imp = [class instanceMethodForSelector:self.selector];
	return imp && imp != [[class superclass] instanceMethodForSelector:self.selector];
}


@end