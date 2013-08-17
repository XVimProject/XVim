//
//  XVimRegister.m
//  XVim
//
//  Created by Nader Akoury on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegister.h"
#import "XVimOptions.h"
#import "XVimEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVim.h"
#import "XVimKeyStroke.h"
#import "Logger.h"

@interface XVimRegister()
@property (strong, nonatomic) XVimMutableString* string;
@end

@implementation XVimRegister

- (id)init{
    if(self = [super init]){
        _string = [[XVimMutableString alloc] init];
        _type = TEXT_TYPE_CHARACTERS;
    }
    return self;
}

- (void)dealloc{
    [_string release];
    [super dealloc];
}

-(void) appendXVimString:(XVimString*)string{
    [self.string appendString:string];
}

-(void) setXVimString:(XVimString*)string{
    [self.string setString:string];
}

-(void) clear{
    [self.string setString:@""];
    self.type = TEXT_TYPE_CHARACTERS;
}

@end

@implementation XVimCurrentFileRegister

-(void) appendXVimString:(XVimString*)string{
    return;
}

-(void) setXVimString:(XVimString*)string{
    return;
}

- (XVimString*)string{
    return [[XVim instance] document];
}

@end

@implementation XVimReadonlyRegister
@end

@implementation XVimClipboardRegister

-(void) appendXVimString:(XVimString*)string{
    NSAssert( false, @"Clipboard register should never be called as appending string");
    return;
}

-(void) setXVimString:(XVimString*)string{
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setString:string forType:NSStringPboardType];
    return;
}

- (XVimString*)string{
    return [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
}

@end

@implementation XVimBlackholeRegister
-(void) appendXVimString:(XVimString*)string{
    return;
}

-(void) setXVimString:(XVimString*)string{
    return;
}

- (XVimString*)string{
    return @"";
}
@end


/**
 * Implementation Note:
 *
 *   XVimRegisterManager takes care of all the register related operations.
 * XVimRegisterManager's methods take all the same input as user specifies it.
 * So XVimRegisterManager client never convert registers to other register.
 * For example, if user specifes "" register Vim uses "0 to yank/delete and
 * make "" points to "0 register. VXimRegisterManager converts "" to "0 internally
 * so the clients do not need to (must not) convert "" to "0.
 *
 * Thus in XVimRegisterManager implementation you always have to convert such registers manually.
 * Becareful when you specify register name in methods arguments.
 * They maybe take "" and convert it or they may not.
 **/

@interface XVimRegisterManager()
@property(strong,nonatomic) NSMutableDictionary* registers;
@property(strong,nonatomic) XVimRegister* recordingRegister;
@property(strong,nonatomic) NSString* recordingRegisterName;
@end


@implementation XVimRegisterManager

static const NSString* s_enum_registers = @"\"0123456789abcdefghijklmnopqrstuvwxyz-*.:%/+~";

#define XVimRegisterWithKeyName(name) [[[XVimRegister alloc] init] autorelease], name
- (id)init{
    if( self = [super init] ){
		_registers =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:
         XVimRegisterWithKeyName(@"\""), // Unnamed register works as if pointer to other register
         XVimRegisterWithKeyName(@"0"),
         XVimRegisterWithKeyName(@"1"),
         XVimRegisterWithKeyName(@"2"),
         XVimRegisterWithKeyName(@"3"),
         XVimRegisterWithKeyName(@"4"),
         XVimRegisterWithKeyName(@"5"),
         XVimRegisterWithKeyName(@"6"),
         XVimRegisterWithKeyName(@"7"),
         XVimRegisterWithKeyName(@"8"),
         XVimRegisterWithKeyName(@"9"),
         
         XVimRegisterWithKeyName(@"-"),
         XVimRegisterWithKeyName(@"a"),
         XVimRegisterWithKeyName(@"b"),
         XVimRegisterWithKeyName(@"c"),
         XVimRegisterWithKeyName(@"d"),
         XVimRegisterWithKeyName(@"e"),
         XVimRegisterWithKeyName(@"f"),
         XVimRegisterWithKeyName(@"g"),
         XVimRegisterWithKeyName(@"h"),
         XVimRegisterWithKeyName(@"i"),
         XVimRegisterWithKeyName(@"j"),
         XVimRegisterWithKeyName(@"k"),
         XVimRegisterWithKeyName(@"l"),
         XVimRegisterWithKeyName(@"m"),
         XVimRegisterWithKeyName(@"n"),
         XVimRegisterWithKeyName(@"o"),
         XVimRegisterWithKeyName(@"p"),
         XVimRegisterWithKeyName(@"q"),
         XVimRegisterWithKeyName(@"r"),
         XVimRegisterWithKeyName(@"s"),
         XVimRegisterWithKeyName(@"t"),
         XVimRegisterWithKeyName(@"u"),
         XVimRegisterWithKeyName(@"v"),
         XVimRegisterWithKeyName(@"w"),
         XVimRegisterWithKeyName(@"x"),
         XVimRegisterWithKeyName(@"y"),
         XVimRegisterWithKeyName(@"z"),
         [[[XVimReadonlyRegister alloc] init] autorelease],    @":",
         [[[XVimReadonlyRegister alloc] init] autorelease],    @".",
         [[[XVimCurrentFileRegister alloc] init] autorelease], @"%",
         [[[XVimReadonlyRegister alloc] init] autorelease],    @"#",
         [[[XVimClipboardRegister alloc] init] autorelease],   @"*",
         XVimRegisterWithKeyName(@"+"),
         XVimRegisterWithKeyName(@"~"),
         [[[XVimBlackholeRegister alloc] init] autorelease],   @"_",
         XVimRegisterWithKeyName(@"/"),
          nil];
        
        _recordingRegister = [[XVimRegister alloc] init];
        _recordingRegisterName = nil;
    }
    return self;
}

- (void)dealloc{
    _recordingRegisterName = nil;
    _recordingRegister = nil;
    _registers = nil;
    [super dealloc];
}

// Private
- (BOOL)isReadonly:(NSString*)name{
    NSAssert( nil != name && name.length == 1 , @"Must be one character");
    XVimRegister* reg = [self registerByName:name];
    if( nil == reg ){
        ERROR_LOG(@"Specified register(%@) can not be found.", name);
        return NO;
    }
    
    if( [[reg class] isSubclassOfClass:[XVimReadonlyRegister class]] ){
        return YES;
    }else{
        return NO;
    }
}

// Private
- (BOOL)isApendingRegister:(NSString*)name{
    NSAssert( name != nil && name.length == 1, @"name must not nil and one character string");
    unichar regChar = [name characterAtIndex:0];
    if( 'A' <= regChar && regChar <= 'Z' ){
        return YES;
    }else{
        return NO;
    }
}

// Private
- (void)setXVimString:(XVimString*)string withType:(TEXT_TYPE)type forReg:(NSString*)reg{
    NSAssert( reg != nil && reg.length == 1, @"name must not nil and one character string");
    XVimRegister* r = [self registerByName:reg];
    [r setXVimString:string];
    r.type = type;
}

// Private
- (void)appendXVimString:(XVimString*)string forReg:(NSString*)reg{
    NSAssert( reg != nil && reg.length == 1, @"name must not nil and one character string");
    XVimRegister* r = [self registerByName:reg];
    [r appendXVimString:string];
}

- (XVimRegister*)registerByName:(NSString*)name{
    NSAssert( name == nil || name.length == 1, @"name must be nil or one character string");
    if( nil == name ){
        if( [[XVim instance].options clipboardHasUnnamed] ){
            name = @"*";
        }else{
            name = @"\"";
        }
    }
    // Always lowercase
    name = [name lowercaseString];
    return [self.registers objectForKey:name];
}

- (BOOL)isValidForYank:(NSString*)name{
    if( nil == name ){
        return YES;
    }
    return ![self isReadonly:name];
}

- (BOOL)isValidForRecording:(NSString*)name{
    NSAssert( nil != name , @"name must be not nil");
    NSAssert( 1 == name.length, @"Register name must be one chraracter");
    
    unichar first = [name characterAtIndex:0];
    if( ('a' <= first && first <= 'z') ||
        ('A' <= first && first <= 'Z') ||
        ('0' <= first && first <= '9') ||
         '"' == first                     ){
        return YES;
    }
    return NO;
}

- (BOOL)isValidRegister:(NSString*)name{
    NSAssert( nil != name , @"name must be not nil");
    NSAssert( 1 == name.length, @"Register name must be one chraracter");
    unichar first = [name characterAtIndex:0];
    if( ('a' <= first && first <= 'z') ||
        ('A' <= first && first <= 'Z') ||
        ('0' <= first && first <= '9') ||
        [[NSCharacterSet characterSetWithCharactersInString:@"\":.%#=*+~_/"] characterIsMember:first]
      ){
        return YES;
    }
    return NO;
}

- (XVimString*)xvimStringForRegister:(NSString*)name{
    NSAssert( name != nil && name.length == 1, @"name must not nil and one character string");
    return [self registerByName:name].string;
}

- (void)yank:(XVimString*)string withType:(TEXT_TYPE)type onRegister:(NSString*)name{
    NSAssert( name == nil || name.length == 1, @"Must be nil or one characrer");
    
    if( nil == name ){
        // When no register is specified
        // update "0
        [self setXVimString:string withType:type forReg:@"0"];
        
        // "" register should point to "0
        [self.registers setObject:[self registerByName:@"0"] forKey:@"\""];
        
        if( [[XVim instance].options clipboardHasUnnamed] ){
            // Update clipboard register too
            [self setXVimString:string withType:type forReg:@"*"];
        }
    }else if( [name isEqualToString:@"\""] ){
        // When "" register is specified
        // Use "0
        [self setXVimString:string withType:type forReg:@"0"];
        
        // "" register should point to "0
        [self.registers setObject:[self registerByName:@"0"] forKey:@"\""];
    }else{
        // When any other register is specified
        // Update reigster content
        if( [self isApendingRegister:name] ){
            [self appendXVimString:string forReg:name];
        }else{
            [self setXVimString:string withType:type forReg:name];
        }
        // "" register should point to the updated register
        [self.registers setObject:[self registerByName:name] forKey:@"\""];
    }
}

- (void)delete:(XVimString*)string withType:(TEXT_TYPE)type onRegister:(NSString*)name{
    // TODO: use "- when deleting does not include \n
    NSAssert( [self isValidForYank:name], @"Must be valid register for yank/delete" );
    
    if( [name isEqualToString:@"_"] ){
        // DO nothing for blackhole register
        return;
    }
    
    if( nil == name ){
        if( [[XVim instance].options clipboardHasUnnamed] ){
            // Update clipboard register too
            [self setXVimString:string withType:type forReg:@"*"];
        }
    }else if( [name isEqualToString:@"\""] ){
        // Update register "0
        [self setXVimString:string withType:type forReg:@"0"];
    }else{
        if( [self isApendingRegister:name] ){
            [self appendXVimString:string forReg:name];
        }else{
            [self setXVimString:string withType:type forReg:name];
        }
    }
    
    // Numbered registers are always updated whatever the register is. (This may be wrong though)
    // Rotate number1 - 9 (Note that not changing registers content but changing references)
    for( unichar n = '8'; n >= '1'; n-- ){
        XVimRegister* r = [self registerByName:[NSString stringWithCharacters:&n length:1]];
        unichar nextReg = n+1;
        [self.registers setObject:r forKey:[NSString stringWithCharacters:&nextReg length:1]];
    }
    // We can not change "1 register content because it is refered by "2 now because of the rotation
    XVimRegister* newReg = [[[XVimRegister alloc] init] autorelease];
    [self.registers setObject:newReg forKey:@"1"];
    [self setXVimString:string withType:type forReg:@"1"];
    
    // Update unnamed register
    [self.registers setObject:newReg forKey:@"\""];
}

- (void)textInserted:(XVimString*)string withType:(TEXT_TYPE)type{
    
}

- (void)commandExecuted:(XVimString*)string withType:(TEXT_TYPE)type{
    
}

- (void)registerExecuted:(NSString *)name{
    self.lastExecutedRegister = name;
}

- (BOOL)isRecording{
    return self.recordingRegisterName != nil;
}

- (void)startRecording:(NSString*)name{
    NSAssert( [self isValidForRecording:name] , @"Must specify valid register for recording");
    NSAssert( self.recordingRegisterName == nil, @"Must be called when not recording.");
    
    if( [@"\"" isEqualToString:name] ){
        name = @"0";
    }
    [self.recordingRegister clear];
    self.recordingRegisterName = name;
}

- (void)record:(XVimString*)string{
    NSAssert( self.recordingRegisterName != nil, @"Must be called when recording.");
    [self.recordingRegister appendXVimString:string];
}

- (void)stopRecording:(BOOL)cancel{
    NSAssert( self.recordingRegister != nil, @"Must be called when recording.");
    XVimRegister* reg = [self registerByName:self.recordingRegisterName];
    if( !cancel) {
        if( [self isApendingRegister:self.recordingRegisterName] ){
            [reg appendXVimString:[self.recordingRegister string]];
        }else{
            [reg setXVimString:[self.recordingRegister string]];
        }
    }
    // TODO: Do I need to update text type here?
    self.recordingRegisterName = nil;
}

- (void)enumerateRegisters:(void (^)(NSString* name, XVimRegister* reg))block{
    for( NSUInteger i = 0 ; i < s_enum_registers.length; i++ ){
        NSString* key = [s_enum_registers substringWithRange:NSMakeRange(i,1)];
        block(key , [self.registers objectForKey:key]);
    }
}

@end
