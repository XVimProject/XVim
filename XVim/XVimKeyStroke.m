//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <wctype.h>
#import <xlocale.h>
#import "XVimKeyStroke.h"
#import "NSEvent+VimHelper.h"
#import "Logger.h"
#import "XVimStringBuffer.h"


/*
 XVimString and Key Notation

 (keymap.h file in Vim source helps understand this better)

 XVim uses internal string encoding as Vim does.
 This encoding is not same as any usual character code because
 the encoding include special flags with characters like modifiers.

 In Vim they treat all the input as a character.
 This is how recordings or keymapping does work.
 Vim uses internal code(character) to express an input(usually a key stroke).
 For example if it is key stroke 'a' internal expression is just ascii 'a'.
 If the key is special like 'backspace' internal expression is 0x80, 'k', 'b' (3byte).
 Vim uses 0x80 as a escape character and followng bytes defines the key.
 Special keys like F1-F10 or S-F1 are all mapped to a 0x80 prefixed value.

 Vim always does following convertings.
 [Phisical Key Input] -> [Vim intarnal code]
 [Key Notation in key map] -> [Vim internal code]

 Key Notatation here is like <F1> or <BS>.

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
     See  or AppKit/NSEvent.h file

 So normal keys like 'a' is just 0x0061 but 'Alt+a' will be 0xF808,0x0061 (4bytes) where 0xF808 represents Alt.

 Note that all the key sequences are represented as array of unichar which is 2byte.
 You have to be careful about endian.
 So the value 'Alt+a' will be 0x08 0xF8 0x61 0x00 in byte sequence(each unichar endian is little endian)
 This makes easy to handle key sequence as NSString.

 Terminology:
   XVimString - The internal key code explained above.
   Notation - Key input represented by readable string like <C-n> or <BS>...

 XVimKeyStroke class:
   This class represents a key input.
   You always can convert XVimString <-> XVimKeyStroke(s).
   Because XVimString is just a sequence of bytes(unichar) it is not usuful to handle in programming.
   So when you handle XVimString you can convert it into XVimKeyStroke(s) and use its property to access
   actuall character or modifier flag values.
   XVimString can represents "Sequence" of key input but XVimKeyStroke represents only one key stroke.
   So if XVimString has several key input it will be converted into array of XVimKeyStorke.

   In other words you can serialize/deserialize XVimKeyStroke(s) with XVimString

 Modifier Flags:
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
// Following values are differed from Vim's definition in keymap.h
#define XVIM_MOD_SHIFT      0x02  //  1 << 1
#define XVIM_MOD_CTRL       0x04  //  1 << 2
#define XVIM_MOD_ALT        0x08  //  1 << 3
#define XVIM_MOD_CMD        0x10  //  1 << 4
#define XVIM_MOD_FUNC       0x80  //  1 << 7  // XVim Original

#define XVIM_MODIFIER_MASK  0x9E  // Mask for used bits. (Change if you add some MOD_MASK_XXX)
#define XVIM_MODIFIER_MIN   0xF802
#define XVIM_MODIFIER_MAX   0xF89E

#define NSMOD2XVIMMOD(x) (((unsigned int)x >> 16) & XVIM_MODIFIER_MASK)
#define XVIMMOD2NSMOD(x) ((unsigned int)x << 16)
#define XVIM_MAKE_MODIFIER(x) ((unsigned short)((KS_MODIFIER<<8) | x ))   // Crate 0xF8XX

struct key_map{
    __unsafe_unretained NSString* key; // Human readable key expression
    unichar c;     // Char code
    __unsafe_unretained NSString* selector; // Selector to be called for evaluators
};

static struct key_map key_maps[] = {
    // If multiple key expressions are mapped to one char code
    // Put default key expression at the end of the same keys.
    // The last one will be used when converting charcode -> key expression.
    { @"NUL",        0, @"NUL"},
    { @"SOH",        1, @"SOH"},
    { @"STX",        2, @"STX"},
    { @"ETX",        3, @"ETX" },
    { @"EOT",        4, @"EOT"},
    { @"ENQ",        5, @"ENQ"},
    { @"ACK",        6, @"ACK"},
    { @"BEL",        7, @"BEL"},
    { @"BS",         8, @"BS" },
    { @"HT",         9, @"TAB"},
    { @"TAB",        9, @"TAB"}, // Default notation
    { @"NL",        10, @"NL"},
    { @"VT",        11, @"VT"},
    { @"NP",        12, @"NP"},
    { @"RETURN",    13, @"CR"},
    { @"ENTER",     13, @"CR"},
    { @"CR",        13, @"CR"}, // Default notation
    { @"SO",        14, @"SO"},
    { @"SI",        15, @"SI"},
    { @"DLE",       16, @"DLE"},
    { @"DC1",       17, @"DC1"},
    { @"DC2",       18, @"DC2"},
    { @"DC3",       19, @"DC3"},
    { @"DC4",       20, @"DC4"},
    { @"NAK",       21, @"NAK"},
    { @"SYN",       22, @"SYN"},
    { @"ETB",       23, @"ETB"},
    { @"CAN",       24, @"CAN"},
    { @"EM",        25, @"EM"},
    { @"SUB",       26, @"SUB"},
    { @"ESC",       27, @"ESC"},
    { @"FS",        28, @"FS"},
    { @"GS",        29, @"GS"},
    { @"RS",        30, @"RS"},
    { @"US",        31, @"US"},
    { @"SPACE",     32, @"SPACE"},
    { @" ",         32, @"SPACE"}, // Default notation
    { @"!",         33, @"EXCLAMATION"},
    { @"\"",        34, @"DQUOTE"},
    { @"#",         35, @"NUMBER"},
    { @"$",         36, @"DOLLAR"},
    { @"%",         37, @"PERCENT"},
    { @"&",         38, @"AMPASAND"},
    { @"'",         39, @"SQUOTE"},
    { @"(",         40, @"LPARENTHESIS"},
    { @")",         41, @"RPARENTHESIS"},
    { @"*",         42, @"ASTERISK"},
    { @"+",         43, @"PLUS"},
    { @",",         44, @"COMMA"},
    { @"-",         45, @"MINUS"},
    { @".",         46, @"DOT"},
    { @"/",         47, @"SLASH"},
    { @"0",         48, @"NUM0"},
    { @"1",         49, @"NUM1"},
    { @"2",         50, @"NUM2"},
    { @"3",         51, @"NUM3"},
    { @"4",         52, @"NUM4"},
    { @"5",         53, @"NUM5"},
    { @"6",         54, @"NUM6"},
    { @"7",         55, @"NUM7"},
    { @"8",         56, @"NUM8"},
    { @"9",         57, @"NUM9"},
    { @":",         58, @"COLON"},
    { @";",         59, @"SEMICOLON"},
    { @"LT",        60, @"LESSTHAN"},
    { @"<",         60, @"LESSTHAN"}, // Default notation
    { @"=",         61, @"EQUAL"},
    { @">",         62, @"GREATERTHAN"},
    { @"?",         63, @"QUESTION"},
    { @"@",         64, @"AT"},
    { @"[",         91, @"LSQUAREBRACKET"},
    { @"BSLASH",    92, @"BACKSLASH"},
    { @"\\",        92, @"BACKSLASH"}, // Default noattion
    { @"]",         93, @"RSQUAREBRACKET"},
    { @"^",         94, @"CARET"},
    { @"_",         95, @"UNDERSCORE"},
    { @"`",         96, @"BACKQUOTE"},
    { @"{",        123, @"LBRACE"},
    { @"BAR",      124, @"BAR"},
    { @"|",        124, @"BAR"}, // Default notation
    { @"}",        125, @"RBRACE"},
    { @"~",        126, @"TILDE"},
    { @"BS",       127, @"BS"},

    { @"UP",            NSUpArrowFunctionKey,       @"Up"           },
    { @"DOWN",          NSDownArrowFunctionKey,     @"Down"         },
    { @"LEFT",          NSLeftArrowFunctionKey,     @"Left"         },
    { @"RIGHT",         NSRightArrowFunctionKey,    @"Right"        },
    { @"F1",            NSF1FunctionKey,            @"F1"           },
    { @"F2",            NSF2FunctionKey,            @"F2"           },
    { @"F3",            NSF3FunctionKey,            @"F3"           },
    { @"F4",            NSF4FunctionKey,            @"F4"           },
    { @"F5",            NSF5FunctionKey,            @"F5"           },
    { @"F6",            NSF6FunctionKey,            @"F6"           },
    { @"F7",            NSF7FunctionKey,            @"F7"           },
    { @"F8",            NSF8FunctionKey,            @"F8"           },
    { @"F9",            NSF9FunctionKey,            @"F9"           },
    { @"F10",           NSF10FunctionKey,           @"F10"          },
    { @"F11",           NSF11FunctionKey,           @"F11"          },
    { @"F12",           NSF12FunctionKey,           @"F12"          },
    { @"F13",           NSF13FunctionKey,           @"F13"          },
    { @"F14",           NSF14FunctionKey,           @"F14"          },
    { @"F15",           NSF15FunctionKey,           @"F15"          },
    { @"F16",           NSF16FunctionKey,           @"F16"          },
    { @"F17",           NSF17FunctionKey,           @"F17"          },
    { @"F18",           NSF18FunctionKey,           @"F18"          },
    { @"F19",           NSF19FunctionKey,           @"F19"          },
    { @"F20",           NSF20FunctionKey,           @"F20"          },
    { @"F21",           NSF21FunctionKey,           @"F21"          },
    { @"F22",           NSF22FunctionKey,           @"F22"          },
    { @"F23",           NSF23FunctionKey,           @"F23"          },
    { @"F24",           NSF24FunctionKey,           @"F24"          },
    { @"F25",           NSF25FunctionKey,           @"F25"          },
    { @"F26",           NSF26FunctionKey,           @"F26"          },
    { @"F27",           NSF27FunctionKey,           @"F27"          },
    { @"F28",           NSF28FunctionKey,           @"F28"          },
    { @"F29",           NSF29FunctionKey,           @"F29"          },
    { @"F30",           NSF30FunctionKey,           @"F30"          },
    { @"F31",           NSF31FunctionKey,           @"F31"          },
    { @"F32",           NSF32FunctionKey,           @"F32"          },
    { @"F33",           NSF33FunctionKey,           @"F33"          },
    { @"F34",           NSF34FunctionKey,           @"F34"          },
    { @"F35",           NSF35FunctionKey,           @"F35"          },
    { @"INS",           NSInsertFunctionKey,        @"Insert"       },

    { @"DEL",           NSDeleteFunctionKey,        @"DEL"          },
    { @"HOME",          NSHomeFunctionKey,          @"Home"         },
    { @"BEGIN",         NSBeginFunctionKey,         @"Begin"        },
    { @"END",           NSEndFunctionKey,           @"End"          },
    { @"PGUP",          NSPageUpFunctionKey,        @"Pageup"       },
    { @"PGDN",          NSPageDownFunctionKey,      @"Pagedown"     },
    { @"PRINTSCREEN",   NSPrintScreenFunctionKey,   @"PrintScreen"  },
    { @"SCREENLOCK",    NSScrollLockFunctionKey,    @"ScrLock"      },
    { @"PAUSE",         NSPauseFunctionKey,         @"Pause"        },
    { @"SYSREQ",        NSSysReqFunctionKey,        @"SysReq"       },
    { @"BREAK",         NSBreakFunctionKey,         @"Break"        },
    { @"RESET",         NSResetFunctionKey,         @"Reset"        },
    { @"STOP",          NSStopFunctionKey,          @"Stop"         },
    { @"MENU",          NSMenuFunctionKey,          @"Menu"         },
    { @"USER",          NSUserFunctionKey,          @"User"         },
    { @"SYSTEM",        NSSystemFunctionKey,        @"System"       },
    { @"PRINT",         NSPrintFunctionKey,         @"Print"        },
    { @"CLEARLINE",     NSClearLineFunctionKey,     @"ClearLine"    },
    { @"CLEARDISPLAY",  NSClearDisplayFunctionKey,  @"ClearDisplay" },
    { @"INSLINE",       NSInsertLineFunctionKey,    @"InsLine"      },
    { @"DELLINE",       NSDeleteLineFunctionKey,    @"DelLine"      },
    { @"INSCHAR",       NSInsertCharFunctionKey,    @"InsChar"      },
    { @"DELCHAR",       NSDeleteCharFunctionKey,    @"DelChar"      },
    { @"PREV",          NSPrevFunctionKey,          @"Prev"         },
    { @"NEXT",          NSNextFunctionKey,          @"Next"         },
    { @"SELECT",        NSSelectFunctionKey,        @"Select"       },
    { @"EXECUTE",       NSExecuteFunctionKey,       @"Execute"      },
    { @"UNDO",          NSUndoFunctionKey,          @"Undo"         },
    { @"REDO",          NSRedoFunctionKey,          @"Redo"         },
    { @"FIND",          NSFindFunctionKey,          @"Find"         },
    { @"HELP",          NSHelpFunctionKey,          @"Help"         },
    { @"MODESWITCH",    NSModeSwitchFunctionKey,    @"ModeSwitch"   },

    { nil, 0, nil },
};

static NSMutableDictionary *s_unicharToSelector = nil;
static NSMutableDictionary *s_keyToUnichar = nil;
static NSMutableDictionary *s_unicharToKey= nil;
static locale_t s_locale;

NS_INLINE void init_maps(void)
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s_unicharToSelector = [[NSMutableDictionary alloc] init]; // Never release
        s_keyToUnichar = [[NSMutableDictionary alloc] init]; // Never release
        s_unicharToKey= [[NSMutableDictionary alloc] init]; // Never release

        for (NSUInteger i = 0; key_maps[i].key; i++) {
            NSNumber *c   = @(key_maps[i].c);
            NSString *key = key_maps[i].key;
            NSString *sel = key_maps[i].selector;

            [s_unicharToSelector setObject:sel forKey:c];
            [s_keyToUnichar      setObject:c   forKey:key];
            [s_unicharToKey      setObject:key forKey:c];
            // any UTF-8 works because we ask for iswprint() or wcwidth()
            s_locale = newlocale(LC_CTYPE_MASK, "en_US.UTF-8", NULL);
        }
    });
}

NS_INLINE BOOL isNSFunctionKey(unichar c)
{
    // see NSEvent.h: OpenStep reserves the range 0xF700-0xF8FF for Function Keys
    return 0xF700 <= c && c < 0xF900;
}

NS_INLINE BOOL isPrintable(unichar c)
{
    init_maps();

    return !isNSFunctionKey(c) && iswprint_l(c, s_locale);
}

NS_INLINE BOOL isValidKey(NSString *key)
{
    init_maps();

    if (key.length == 0) {
        return NO;
    }
    if (key.length == 1) {
        return isPrintable([key characterAtIndex:0]);
    }

    return [s_keyToUnichar objectForKey:key.uppercaseString] != 0;
}

NS_INLINE unichar unicharFromKey(NSString *key)
{
    init_maps();

    if (key.length == 0) {
        return (unichar)-1;
    }
    if (key.length == 1) {
        unichar c = [key characterAtIndex:0];

        return isPrintable(c) ? c : (unichar)-1;
    }

    return [[s_keyToUnichar objectForKey:key.uppercaseString] unsignedIntegerValue];
}

NS_INLINE NSString *keyFromUnichar(unichar c)
{
    init_maps();

    NSString *key = [s_unicharToKey objectForKey:@(c)];
    if (key) {
        return key;
    }
    if (isPrintable(c)) {
        return [NSString stringWithCharacters:&c length:1];
    }
    return @"?";
}

NS_INLINE BOOL isModifier(unichar c)
{
    return (XVIM_MODIFIER_MIN <= c && c <= XVIM_MODIFIER_MAX);
}

static XVimString *MakeXVimString(unichar character, unsigned short modifier)
{
    NSMutableString *str = [[NSMutableString alloc] init];

    init_maps();

    // If the character is pritable we do not consider Shift modifier
    // For example <S-!> and ! is same
    if (isPrintable(character)) {
        modifier = modifier & ~XVIM_MOD_SHIFT;
    }
    if (modifier != 0) {
        [str appendFormat:@"%C", XVIM_MAKE_MODIFIER(modifier)];
    }
    [str appendFormat:@"%C", character];
    return str;
}

static XVimString *XVimStringFromKeyNotationImpl(NSString *string, NSUInteger *index)
{
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

            NSString *key = [string substringWithRange:NSMakeRange(p, keyEnd.location-p)];
            if (isValidKey(key)) {
                if (0 == modifierFlags) {
                    //If it does not have modifier flag the key must be multiple letters
                    if ([key length] > 1) {
                        *index = keyEnd.location+1;
                        unichar c = unicharFromKey(key);
                        return MakeXVimString(c, modifierFlags);
                    }
                } else {
                    //This is modifier flag + valid key
                    *index = keyEnd.location+1;
                    unichar c = unicharFromKey(key);
                    return MakeXVimString(c, modifierFlags);
                }
            }
        }
        // if it not valid key like "<a>" or "<c>" take first letter "<" as a key
        // Just go through.
    }

    // Simple one letter key
    NSString* key = [string substringWithRange:NSMakeRange(starti, 1)];
    unichar c = unicharFromKey(key);
    *index = starti+1;
    return MakeXVimString(c, modifierFlags);
}

XVimString* XVimStringFromKeyNotation(NSString* notation){
    NSUInteger index = 0;
    NSUInteger len = notation.length;
    NSMutableString* str = [[NSMutableString alloc] init];
    while (index < len){
        XVimString* oneKey = XVimStringFromKeyNotationImpl(notation, &index);
        if( oneKey == nil ){
            break;
        }
        [str appendString:oneKey];
    }
    return str;
}

XVimString* XVimStringFromKeyStrokes(NSArray* strokes){
    NSMutableString* str = [[NSMutableString alloc] init];
    for( XVimKeyStroke* stroke in strokes ){
        [str appendString:[stroke xvimString]];
    }
    return str;
}

NSArray* XVimKeyStrokesFromXVimString(XVimString* string){
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for( NSUInteger i = 0; i < string.length; i++ ){
        unichar c1 = [string characterAtIndex:i];
        unichar c2;
        if( isModifier( c1 ) ){
            i++;
            c2 = [string characterAtIndex:i];
        }else{
            c2 = c1;
            c1 = 0;
        }

        XVimKeyStroke* stroke = [[XVimKeyStroke alloc] initWithCharacter:c2 modifier:c1];
        [array addObject:stroke];
    }
    return array;
}

NSArray* XVimKeyStrokesFromKeyNotation(NSString* notation){
    return XVimKeyStrokesFromXVimString(XVimStringFromKeyNotation(notation));
}

NSString* XVimKeyNotationFromXVimString(XVimString* string){
    NSArray* array = XVimKeyStrokesFromXVimString(string);
    NSMutableString* str = [[NSMutableString alloc] init];
    for( XVimKeyStroke* stroke in array ){
        [str appendString:[stroke keyNotation]];
    }
    return str;
}

@implementation NSEvent(XVimKeyStroke)

- (XVimKeyStroke*)toXVimKeyStroke{
    if( [self charactersIgnoringModifiers].length == 0 ){
        return nil;
    }
    unichar c = [[self charactersIgnoringModifiers] characterAtIndex:0];
    NSUInteger mod = self.modifierFlags;
    if (isNSFunctionKey(c)) {
        // We unset NSFunctionKeyMask bit for function keys (7F00 and above)
        mod &= (NSUInteger)~NSFunctionKeyMask;
    }
    if (c == 0x19 && (mod & NSDeviceIndependentModifierFlagsMask) == NSShiftKeyMask) {
        // S-EM really is S-Tab
        c = '\t';
    }
    mod = NSMOD2XVIMMOD(mod);
    return [[XVimKeyStroke alloc] initWithCharacter:c modifier:(unsigned char)mod];
}

- (XVimString*)toXVimString{
    NSAssert( self.type == NSKeyDown , @"Event type must be NSKeyDown");
    return [[self toXVimKeyStroke] xvimString];
}
@end


@implementation XVimKeyStroke
@synthesize character = _character, modifier = _modifier;

+ (void)initialize
{
    init_maps();
}

- (id)initWithCharacter:(unichar)c modifier:(unsigned char)mod{
    if( self = [super init] ){
        _character = c;
        _modifier = mod;
    }
    return self;
}

- (XVimString*)xvimString{
    return MakeXVimString(_character, _modifier);
}

- (BOOL) isNumeric{
    return _modifier == 0 && ('0' <= _character && _character <= '9');
}

- (NSUInteger)hash{
    return _modifier + _character;
}

- (BOOL)isEqual:(id)object{
    if (object == self) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]){
        return NO;
    }
    XVimKeyStroke* other = object;
    return _character == other.character && _modifier== other.modifier;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[XVimKeyStroke allocWithZone:zone] initWithCharacter:_character modifier:_modifier];
}

- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(NSGraphicsContext*)context; {
    unichar c = _character;
    NSString *characters = [NSString stringWithCharacters:&c length:1];
    NSUInteger mflags = XVIMMOD2NSMOD(_modifier);

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
    NSMutableString *str = [[NSMutableString alloc] init];

    if (0 != _modifier) {
        [str appendFormat:@"mod{0x%02x 0x%02x} ", KS_MODIFIER, _modifier];
    }

    unichar c = _character;
    if (isPrintable(c)) {
        [str appendFormat:@"code{%C} ", c];
    }else{
        [str appendFormat:@"code{0u%04x} ", c];
    }
    [str appendString:[self keyNotation]];

    return str;
}

- (BOOL)isPrintable
{
    return !_modifier && isPrintable(_character);
}

- (NSString*)keyNotation{
    NSMutableString *keyStr = [[NSMutableString alloc] init];
    unichar charcode = _character;

    if (_modifier || !isPrintable(charcode)) {
        [keyStr appendString:@"<"];
    }

    if (_modifier & XVIM_MOD_SHIFT) {
        [keyStr appendString:@"S-"];
    }
    if (_modifier & XVIM_MOD_CTRL) {
        [keyStr appendString:@"C-"];
    }
    if (_modifier & XVIM_MOD_ALT) {
        [keyStr appendString:@"M-"];
    }
    if (_modifier & XVIM_MOD_CMD) {
        [keyStr appendString:@"D-"];
    }
    if (_modifier & XVIM_MOD_FUNC) {
        [keyStr appendString:@"F-"];
    }

    [keyStr appendString:keyFromUnichar(charcode)];

    if (_modifier || !isPrintable(charcode)) {
        [keyStr appendString:@">"];
    }
    return keyStr;
}

- (SEL)selector
{
	// S- Shift
	// C- Control
	// M- Option
	// D- Command
    // F_ Function (not F1,F2.. but 'Function' key)
    char buf[128];
    int pos = 0;

    if (_modifier & XVIM_MOD_SHIFT) {
        buf[pos++] = 'S'; buf[pos++] = '_';
    }
    if (_modifier & XVIM_MOD_CTRL) {
        buf[pos++] = 'C'; buf[pos++] = '_';
    }
    if (_modifier & XVIM_MOD_ALT) {
        buf[pos++] = 'M'; buf[pos++] = '_';
    }
    if (_modifier & XVIM_MOD_CMD) {
        buf[pos++] = 'D'; buf[pos++] = '_';
    }
    if (_modifier & XVIM_MOD_FUNC) {
        buf[pos++] = 'F'; buf[pos++] = '_';
    }

    if ((_character >= 'a' && _character <= 'z') || (_character >= 'A' && _character <= 'Z')) {
        buf[pos++] = _character;
        buf[pos++] = '\0';
    } else {
        NSString *keyname = [s_unicharToSelector objectForKey:@(_character)];

        if (!keyname) {
            return @selector(__invalid_selector_name__);
        }
        strcpy(buf + pos, keyname.UTF8String);
    }

    return sel_getUid(buf);
}

- (BOOL)isCTRLModifier{
    return _modifier == XVIM_MOD_CTRL;
}
@end
