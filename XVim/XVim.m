//
//  XVim.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

// This is the main class of XVim
// The main role of XVim class is followings.
//    - create hooks.
//    - provide methods used by all over the XVim features.
//
// Hooks:
// The plugin entry point is "load" but does little thing.
// The important method after that is hook method.
// In this method we create hooks necessary for XVim initializing.
// The most important hook is hook for IDEEditorArea and DVTSourceTextView.
// These hook setup command line and intercept key input to the editors.
//
// Methods:
// XVim is a singleton instance and holds objects which can be used by all the features in XVim.
// See the implementation to know what kind of objects it has. They are not difficult to understand.
// 



#import "XVim.h"
#import "Logger.h"
#import "XVimSearch.h"
#import "XVimCharacterSearch.h"
#import "XVimExCommand.h"
#import "XVimKeymap.h"
#import "XVimMode.h"
#import "XVimRegister.h"
#import "XVimKeyStroke.h"
#import "XVimOptions.h"
#import "XVimHistoryHandler.h"
#import "XVimHookManager.h"
#import "XVimCommandLine.h"

static XVim* s_instance = nil;

@interface XVim() {
	XVimHistoryHandler *_exCommandHistory;
	XVimHistoryHandler *_searchHistory;
	XVimKeymap* _keymaps[MODE_COUNT];
    NSFileHandle* _logFile;
}
- (void)parseRcFile;
@property (strong) NSArray *numberedRegisters;
@end

@implementation XVim
@synthesize registers = _registers;
@synthesize repeatRegister = _repeatRegister;
@synthesize recordingRegister = _recordingRegister;
@synthesize lastPlaybackRegister = _lastPlaybackRegister;
@synthesize numberedRegisters = _numberedRegisters;
@synthesize searcher = _searcher;
@synthesize characterSearcher = _characterSearcher;
@synthesize excmd = _excmd;
@synthesize options = _options;
@synthesize document = _document;

+(void)receiveNotification:(NSNotification*)notification{
    if( [notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"] ){
        TRACE_LOG(@"Got notification name : %@    object : %@", notification.name, NSStringFromClass([[notification object] class]));
    }
}

+ (void) load 
{ 
    NSBundle* app = [NSBundle mainBundle];
    NSString* identifier = [app bundleIdentifier];
    
    if( ![identifier isEqualToString:@"com.apple.dt.Xcode"] ){
        return;
    }
    // Entry Point of the Plugin.
    [Logger defaultLogger].level = LogTrace;
	
	// Allocate singleton instance
	s_instance = [[XVim alloc] init];
    [s_instance.options addObserver:s_instance forKeyPath:@"debug" options:NSKeyValueObservingOptionNew context:nil];
	[s_instance parseRcFile];
    
    TRACE_LOG(@"XVim loaded");
    
    // This is for reverse engineering purpose. Comment this in and log all the notifications named "IDE" or "DVT"
    //[[NSNotificationCenter defaultCenter] addObserver:[XVim class] selector:@selector(receiveNotification:) name:nil object:nil];
    
    // Do the hooking after the App has finished launching,
    // Otherwise, we may miss some classes.

    // Command line window is not setuped if hook is too late.
    [XVimHookManager hookWhenPluginLoaded];

    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: [XVimHookManager class]
                                  selector: @selector( hookWhenDidFinishLaunching )
                                   name: NSApplicationDidFinishLaunchingNotification
                                 object: nil];
}

+ (XVim*)instance
{
	return s_instance;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id)init
{
	if (self = [super init])
	{
		_excmd = [[XVimExCommand alloc] init];
		_exCommandHistory = [[XVimHistoryHandler alloc] init];
		_searchHistory = [[XVimHistoryHandler alloc] init];
		_searcher = [[XVimSearch alloc] init];
		_characterSearcher = [[XVimCharacterSearch alloc] init];
		_options = [[XVimOptions alloc] init];
		// From the vim documentation:
		// There are nine types of registers:
		// *registers* *E354*
		_registers =
        [NSDictionary dictionaryWithObjectsAndKeys:
		 // 1. The unnamed register ""
		 [[XVimRegister alloc] initWithDisplayName:@"\""] ,@"DQUOTE", 
		 // 2. 10 numbered registers "0 to "9 
		 [[XVimRegister alloc] initWithDisplayName:@"0"] ,@"NUM0", 
		 [[XVimRegister alloc] initWithDisplayName:@"1"] ,@"NUM1", 
		 [[XVimRegister alloc] initWithDisplayName:@"2"] ,@"NUM2", 
		 [[XVimRegister alloc] initWithDisplayName:@"3"] ,@"NUM3", 
		 [[XVimRegister alloc] initWithDisplayName:@"4"] ,@"NUM4", 
		 [[XVimRegister alloc] initWithDisplayName:@"5"] ,@"NUM5", 
		 [[XVimRegister alloc] initWithDisplayName:@"6"] ,@"NUM6", 
		 [[XVimRegister alloc] initWithDisplayName:@"7"] ,@"NUM7", 
		 [[XVimRegister alloc] initWithDisplayName:@"8"] ,@"NUM8", 
		 [[XVimRegister alloc] initWithDisplayName:@"9"] ,@"NUM9", 
		 // 3. The small delete register "-
		 [[XVimRegister alloc] initWithDisplayName:@"-"] ,@"DASH", 
		 // 4. 26 named registers "a to "z or "A to "Z
		 [[XVimRegister alloc] initWithDisplayName:@"a"] ,@"a", 
		 [[XVimRegister alloc] initWithDisplayName:@"b"] ,@"b", 
		 [[XVimRegister alloc] initWithDisplayName:@"c"] ,@"c", 
		 [[XVimRegister alloc] initWithDisplayName:@"d"] ,@"d", 
		 [[XVimRegister alloc] initWithDisplayName:@"e"] ,@"e", 
		 [[XVimRegister alloc] initWithDisplayName:@"f"] ,@"f", 
		 [[XVimRegister alloc] initWithDisplayName:@"g"] ,@"g", 
		 [[XVimRegister alloc] initWithDisplayName:@"h"] ,@"h", 
		 [[XVimRegister alloc] initWithDisplayName:@"i"] ,@"i", 
		 [[XVimRegister alloc] initWithDisplayName:@"j"] ,@"j", 
		 [[XVimRegister alloc] initWithDisplayName:@"k"] ,@"k", 
		 [[XVimRegister alloc] initWithDisplayName:@"l"] ,@"l", 
		 [[XVimRegister alloc] initWithDisplayName:@"m"] ,@"m", 
		 [[XVimRegister alloc] initWithDisplayName:@"n"] ,@"n", 
		 [[XVimRegister alloc] initWithDisplayName:@"o"] ,@"o", 
		 [[XVimRegister alloc] initWithDisplayName:@"p"] ,@"p", 
		 [[XVimRegister alloc] initWithDisplayName:@"q"] ,@"q", 
		 [[XVimRegister alloc] initWithDisplayName:@"r"] ,@"r", 
		 [[XVimRegister alloc] initWithDisplayName:@"s"] ,@"s", 
		 [[XVimRegister alloc] initWithDisplayName:@"t"] ,@"t", 
		 [[XVimRegister alloc] initWithDisplayName:@"u"] ,@"u", 
		 [[XVimRegister alloc] initWithDisplayName:@"v"] ,@"v", 
		 [[XVimRegister alloc] initWithDisplayName:@"w"] ,@"w", 
		 [[XVimRegister alloc] initWithDisplayName:@"x"] ,@"x", 
		 [[XVimRegister alloc] initWithDisplayName:@"y"] ,@"y", 
		 [[XVimRegister alloc] initWithDisplayName:@"z"] ,@"z", 
		 // 5. four read-only registers ":, "., "% and "#
		 [[XVimRegister alloc] initWithDisplayName:@":"] ,@"COLON", 
		 [[XVimRegister alloc] initWithDisplayName:@"."] ,@"DOT", 
		 [[XVimRegister alloc] initWithDisplayName:@"%"] ,@"PERCENT", 
		 [[XVimRegister alloc] initWithDisplayName:@"#"] ,@"NUMBER", 
		 // 6. the expression register "=
		 [[XVimRegister alloc] initWithDisplayName:@"="] ,@"EQUAL", 
		 // 7. The selection and drop registers "*, "+ and "~  
		 [[XVimRegister alloc] initWithDisplayName:@"*"] ,@"ASTERISK", 
		 [[XVimRegister alloc] initWithDisplayName:@"+"] ,@"PLUS", 
		 [[XVimRegister alloc] initWithDisplayName:@"~"] ,@"TILDE", 
		 // 8. The black hole register "_
		 [[XVimRegister alloc] initWithDisplayName:@"_"] ,@"UNDERSCORE", 
		 // 9. Last search pattern register "/
		 [[XVimRegister alloc] initWithDisplayName:@"/"] ,@"SLASH", 
		 // additional "hidden" register to store text for '.' command
		 [[XVimRegister alloc] initWithDisplayName:@"repeat"] ,@"repeat", 
		 nil];

        _numberedRegisters =
        [NSArray arrayWithObjects:
         [_registers valueForKey:@"NUM0"],
         [_registers valueForKey:@"NUM1"],
         [_registers valueForKey:@"NUM2"],
         [_registers valueForKey:@"NUM3"],
         [_registers valueForKey:@"NUM4"],
         [_registers valueForKey:@"NUM5"],
         [_registers valueForKey:@"NUM6"],
         [_registers valueForKey:@"NUM7"],
         [_registers valueForKey:@"NUM8"],
         [_registers valueForKey:@"NUM9"],
         nil];
        
        _recordingRegister = nil;
        _lastPlaybackRegister = nil;
        _repeatRegister = [_registers valueForKey:@"repeat"];
        _logFile = nil;
        
		for (int i = 0; i < MODE_COUNT; ++i)
		{
			_keymaps[i] = [[XVimKeymap alloc] init];
		}
		[XVimKeyStroke initKeymaps];
        
	}
	return self;
}


-(void)dealloc{
    [_options release];
    [_searcher release];
	[_characterSearcher release];
    [_excmd release];
    [_logFile release];
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"debug"]) {
        if( [s_instance options].debug ){
            NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
            NSString *logPath = [homeDir stringByAppendingString: @"/.xvimlog"]; 
            [[Logger defaultLogger] setLogFile:logPath];
        }else{
            [[Logger defaultLogger] setLogFile:nil];
        }
    } else if( [keyPath isEqualToString:@"document"] ){
        self.document = [[[object document] fileURL] path];
    }
}
    
- (void)parseRcFile {
    NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString *keymapPath = [homeDir stringByAppendingString: @"/.xvimrc"]; 
    NSString *keymapData = [[NSString alloc] initWithContentsOfFile:keymapPath 
                                                           encoding:NSUTF8StringEncoding
															  error:NULL];
	for (NSString *string in [keymapData componentsSeparatedByString:@"\n"])
	{
		[self.excmd executeCommand:[@":" stringByAppendingString:string] inWindow:nil];
	}
}

- (void)writeToLogfile:(NSString*)str{
    return;
    if( ![[self.options getOption:@"debug"] boolValue] ){
        return;
    }
    
    NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString *logPath = [homeDir stringByAppendingString: @"/.xvimlog"]; 
     if( nil == _logFile){
        NSFileManager* fm = [NSFileManager defaultManager];
         if( [fm fileExistsAtPath:logPath] ){
            [fm removeItemAtPath:logPath error:nil];
        }
        [fm createFileAtPath:logPath contents:nil attributes:nil];
         _logFile = [[NSFileHandle fileHandleForWritingAtPath:logPath] retain]; // Do we need to retain this? I want to use this handle as long as Xvim is alive.
        [_logFile seekToEndOfFile];
    }
    
    [_logFile writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}
- (XVimKeymap*)keymapForMode:(int)mode {
	return _keymaps[mode];
}

- (XVimRegister*)findRegister:(NSString*)name{
    return [self.registers valueForKey:name];
}

- (XVimHistoryHandler*)exCommandHistory
{
    return _exCommandHistory;
}

- (XVimHistoryHandler*)searchHistory
{
	return _searchHistory;
}

- (void)ringBell {
    if (_options.errorbells) {
        NSBeep();
    }
    return;
}

- (void)onDeleteOrYank:(XVimRegister*)yankRegister
                  text:(NSString*)text
{
    // Don't do anything if we are recording into a register (that isn't the repeat register)
    if (self.recordingRegister != nil){
        return;
    }

    // If we are yanking into a specific register then we do not cycle through
    // the numbered registers.
    if ([yankRegister.displayName isEqualToString:@"*"]){
        [[NSPasteboard generalPasteboard] setString:text forType:NSStringPboardType];
    }
    else if (yankRegister != nil){
        [yankRegister clear];
        [yankRegister appendText:text];
    }
    else {
        // There are 10 numbered registers
        for (NSUInteger i = self.numberedRegisters.count - 2; ; --i){
            XVimRegister *prev = [self.numberedRegisters objectAtIndex:i];
            XVimRegister *next = [self.numberedRegisters objectAtIndex:i+1];
            
            [next clear];
            [next appendText:prev.text];
            if( i == 0 ){
                break;
            }
        }
        
        XVimRegister *reg = [self.numberedRegisters objectAtIndex:0];
        [reg clear];
        [reg appendText:text];
        
        if ( self.options.pasteboard ) {
            [[NSPasteboard generalPasteboard] setString:text forType:NSStringPboardType];
        }
    }
    
    XVimRegister *defaultReg = [self findRegister:@"DQUOTE"];
    [defaultReg clear];
    [defaultReg appendText:text];
}

- (NSString*)pasteText:(XVimRegister*)yankRegister
{
    if ([yankRegister.displayName isEqualToString:@"*"]) {
        return [[NSPasteboard generalPasteboard]stringForType:NSStringPboardType];
    }
	else if (yankRegister)
	{
		return yankRegister.text;
	}
    else if (self.options.pasteboard) {
        return [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
    }
    else {
        return [[self findRegister:@"DQUOTE"] text];
    }
}

@end
