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
#import "DVTSourceTextViewHook.h"
#import "XVimMarks.h"

NSString * const XVimDocumentChangedNotification = @"XVimDocumentChangedNotification";
NSString * const XVimDocumentPathKey = @"XVimDocumentPathKey";

@interface XVim() {
	XVimHistoryHandler *_exCommandHistory;
	XVimHistoryHandler *_searchHistory;
	XVimKeymap* _keymaps[MODE_COUNT];
    NSFileHandle* _logFile;
}
- (void)parseRcFile;
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
@synthesize marks = _marks;
@synthesize document = _document;

// For reverse engineering purpose.
+(void)receiveNotification:(NSNotification*)notification{
    if( [notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"] ){
        TRACE_LOG(@"Got notification name : %@    object : %@", notification.name, NSStringFromClass([[notification object] class]));
    }
}

- (void)toggleXVim:(id)sender{
    if( [sender state] == NSOnState ){
        [DVTSourceTextViewHook unhook];
        [sender setState:NSOffState];
    }else{
        [DVTSourceTextViewHook hook];
        [sender setState:NSOnState];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    return YES;
}

+ (void) load 
{ 
    NSBundle* app = [NSBundle mainBundle];
    NSString* identifier = [app bundleIdentifier];
    
    // Load only into Xcode
    if( ![identifier isEqualToString:@"com.apple.dt.Xcode"] ){
        return;
    }
    // Entry Point of the Plugin.
    [Logger defaultLogger].level = LogTrace;
    
    // Add XVim menu item in "Edit"
    // I have tried to add the item into "Editor" but did not work.
    // It looks that the initialization of "Editor" menu is after loading XVim...
    NSMenu* menu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem* item = [[[NSMenuItem alloc] init] autorelease];
    item.title = @"XVim";
    [item setEnabled:YES];
    item.target = [XVim instance];
    
    //Caution: parseRcFile can potentially invoke +instance on XVim (e.g. if "set ..." is
    //used in .ximvrc) so we must be sure to call it _AFTER_ +instance has completed
    [item.target parseRcFile];
    
    
    item.action = @selector(toggleXVim:);
    item.state = NSOnState;
    NSMenuItem* editorManu = [menu itemWithTitle:@"Edit"];
    NSMenu* editorSubMenu = [editorManu submenu];
    [editorSubMenu addItem:item];
    
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
    static XVim *__instance = nil;
    static dispatch_once_t __once;
    
    dispatch_once(&__once, ^{
        // Allocate singleton instance
        __instance = [[XVim alloc] init];
        [__instance.options addObserver:__instance forKeyPath:@"debug" options:NSKeyValueObservingOptionNew context:nil];
        
        TRACE_LOG(@"XVim loaded");
    });
	return __instance;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id)init {
	if (self = [super init]) {
		_excmd = [[XVimExCommand alloc] init];
		_exCommandHistory = [[XVimHistoryHandler alloc] init];
		_searchHistory = [[XVimHistoryHandler alloc] init];
		_searcher = [[XVimSearch alloc] init];
		_characterSearcher = [[XVimCharacterSearch alloc] init];
		_options = [[XVimOptions alloc] init];
        _marks = [[XVimMarks alloc] init];
		// From the vim documentation:
		// There are nine types of registers:
		// *registers* *E354*
		_registers =
        [[NSDictionary alloc] initWithObjectsAndKeys:
		 // 1. The unnamed register ""
		 [XVimRegister registerWithDisplayName:@"\""] ,@"DQUOTE", 
		 // 2. 10 numbered registers "0 to "9 
		 [XVimRegister registerWithDisplayName:@"0"] ,@"NUM0", 
		 [XVimRegister registerWithDisplayName:@"1"] ,@"NUM1", 
		 [XVimRegister registerWithDisplayName:@"2"] ,@"NUM2", 
		 [XVimRegister registerWithDisplayName:@"3"] ,@"NUM3", 
		 [XVimRegister registerWithDisplayName:@"4"] ,@"NUM4", 
		 [XVimRegister registerWithDisplayName:@"5"] ,@"NUM5", 
		 [XVimRegister registerWithDisplayName:@"6"] ,@"NUM6", 
		 [XVimRegister registerWithDisplayName:@"7"] ,@"NUM7", 
		 [XVimRegister registerWithDisplayName:@"8"] ,@"NUM8", 
		 [XVimRegister registerWithDisplayName:@"9"] ,@"NUM9", 
		 // 3. The small delete register "-
		 [XVimRegister registerWithDisplayName:@"-"] ,@"DASH", 
		 // 4. 26 named registers "a to "z or "A to "Z
		 [XVimRegister registerWithDisplayName:@"a"] ,@"a", 
		 [XVimRegister registerWithDisplayName:@"b"] ,@"b", 
		 [XVimRegister registerWithDisplayName:@"c"] ,@"c", 
		 [XVimRegister registerWithDisplayName:@"d"] ,@"d", 
		 [XVimRegister registerWithDisplayName:@"e"] ,@"e", 
		 [XVimRegister registerWithDisplayName:@"f"] ,@"f", 
		 [XVimRegister registerWithDisplayName:@"g"] ,@"g", 
		 [XVimRegister registerWithDisplayName:@"h"] ,@"h", 
		 [XVimRegister registerWithDisplayName:@"i"] ,@"i", 
		 [XVimRegister registerWithDisplayName:@"j"] ,@"j", 
		 [XVimRegister registerWithDisplayName:@"k"] ,@"k", 
		 [XVimRegister registerWithDisplayName:@"l"] ,@"l", 
		 [XVimRegister registerWithDisplayName:@"m"] ,@"m", 
		 [XVimRegister registerWithDisplayName:@"n"] ,@"n", 
		 [XVimRegister registerWithDisplayName:@"o"] ,@"o", 
		 [XVimRegister registerWithDisplayName:@"p"] ,@"p", 
		 [XVimRegister registerWithDisplayName:@"q"] ,@"q", 
		 [XVimRegister registerWithDisplayName:@"r"] ,@"r", 
		 [XVimRegister registerWithDisplayName:@"s"] ,@"s", 
		 [XVimRegister registerWithDisplayName:@"t"] ,@"t", 
		 [XVimRegister registerWithDisplayName:@"u"] ,@"u", 
		 [XVimRegister registerWithDisplayName:@"v"] ,@"v", 
		 [XVimRegister registerWithDisplayName:@"w"] ,@"w", 
		 [XVimRegister registerWithDisplayName:@"x"] ,@"x", 
		 [XVimRegister registerWithDisplayName:@"y"] ,@"y", 
		 [XVimRegister registerWithDisplayName:@"z"] ,@"z", 
		 // 5. four read-only registers ":, "., "% and "#
		 [XVimRegister registerWithDisplayName:@":"] ,@"COLON", 
		 [XVimRegister registerWithDisplayName:@"."] ,@"DOT", 
		 [XVimRegister registerWithDisplayName:@"%"] ,@"PERCENT", 
		 [XVimRegister registerWithDisplayName:@"#"] ,@"NUMBER", 
		 // 6. the expression register "=
		 [XVimRegister registerWithDisplayName:@"="] ,@"EQUAL", 
		 // 7. The selection and drop registers "*, "+ and "~  
		 [XVimRegister registerWithDisplayName:@"*"] ,@"ASTERISK", 
		 [XVimRegister registerWithDisplayName:@"+"] ,@"PLUS", 
		 [XVimRegister registerWithDisplayName:@"~"] ,@"TILDE", 
		 // 8. The black hole register "_
		 [XVimRegister registerWithDisplayName:@"_"] ,@"UNDERSCORE", 
		 // 9. Last search pattern register "/
		 [XVimRegister registerWithDisplayName:@"/"] ,@"SLASH", 
		 // additional "hidden" register to store text for '.' command
		 [XVimRegister registerWithDisplayName:@"repeat"] ,@"repeat",
		 nil];
        
        _numberedRegisters = [[NSArray alloc] initWithObjects:
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
        
		for (int i = 0; i < MODE_COUNT; ++i) {
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
    [_numberedRegisters release];
    [_marks release];
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"debug"]) {
        if( [[XVim instance] options].debug ){
            NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
            NSString *logPath = [homeDir stringByAppendingString: @"/.xvimlog"]; 
            [[Logger defaultLogger] setLogFile:logPath];
        }else{
            [[Logger defaultLogger] setLogFile:nil];
        }
    } else if( [keyPath isEqualToString:@"document"] ){
        NSString *documentPath = [[[object document] fileURL] path];
        self.document = documentPath;
        
        if (documentPath != nil) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:documentPath forKey:XVimDocumentPathKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:XVimDocumentChangedNotification object:nil userInfo:userInfo];
        }
    }
}
    
- (void)parseRcFile {
    NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString *keymapPath = [homeDir stringByAppendingString: @"/.xvimrc"]; 
    NSString *keymapData = [[[NSString alloc] initWithContentsOfFile:keymapPath
                                                           encoding:NSUTF8StringEncoding
															  error:NULL] autorelease];
	for (NSString *string in [keymapData componentsSeparatedByString:@"\n"])
	{
		[self.excmd executeCommand:[@":" stringByAppendingString:string] inWindow:nil];
	}
}

- (void)writeToLogfile:(NSString*)str{
    if( ![[self.options getOption:@"debug"] boolValue] ){
        return;
    }
    
    if( nil == _logFile){
        NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
        NSString *logPath = [homeDir stringByAppendingString: @"/.xvimlog"]; 
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
    if( [name isEqualToString:@"DQUOTE"] && [self.options.clipboard rangeOfString:@"unnamed"].location != NSNotFound ){
       name = @"ASTERISK";
    }
    return [self.registers valueForKey:name];
}

- (XVimHistoryHandler*)exCommandHistory {
    return _exCommandHistory;
}

- (XVimHistoryHandler*)searchHistory {
	return _searchHistory;
}

- (void)ringBell {
    if (_options.errorbells) {
        NSBeep();
    }
    return;
}

@end
