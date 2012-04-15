//
//  XVim.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVim.h"

// Xcode View hieralchy
//
//  IDESourceCodeEdiorContainerView
//           |
//           |- DVTSourceTextScrollView    <-- enclosingScrollView from DVTSourceView
//                     |- NSClipView
//                     |      |- DVTSourceTextView
//                     |- DVTMarkedScroller <- vertical scrollbar
//                     |- NSScroller <- horizontal scrollbar
//                     |- DVTTextSidebarView <- area to display line number or debug point
//                     

//
//  DVTSourceTextView
//         |- DVTFoldingTextStorage (textStorage property)
//                    |- DVTFontAndColorsTheme (fontAndColorsTheme property)
//

#import "Logger.h"
#import "Hooker.h"
#import "XVimSearch.h"
#import "XVimCharacterSearch.h"
#import "XVimExCommand.h"
#import "XVimSourceTextView.h"
#import "XVimSourceCodeEditor.h"
#import "XVimKeymap.h"
#import "XVimMode.h"
#import "XVimRegister.h"
#import "XVimKeyStroke.h"
#import "XVimOptions.h"
#import "XVimHistoryHandler.h"

static XVim* s_instance = nil;

@interface XVim() {
	XVimHistoryHandler *_exCommandHistory;
	XVimHistoryHandler *_searchHistory;
	XVimKeymap* _keymaps[MODE_COUNT];
}
- (void)parseRcFile;
@property (strong) NSArray *numberedRegisters;
@end

@implementation XVim
@synthesize registers = _registers;
@synthesize yankRegister = _yankRegister;
@synthesize repeatRegister = _repeatRegister;
@synthesize recordingRegister = _recordingRegister;
@synthesize lastPlaybackRegister = _lastPlaybackRegister;
@synthesize numberedRegisters = _numberedRegisters;
@synthesize searcher = _searcher;
@synthesize characterSearcher = _characterSearcher;
@synthesize excmd = _excmd;
@synthesize options = _options;
@synthesize editor = _editor;

+ (void) load { 
    // Entry Point of the Plugin.
    // Hook methods ( mainly of DVTSourceTextView" )
    
    [Logger defaultLogger].level = LogTrace;
    TRACE_LOG(@"XVim loaded");
	
	// Allocate singleton instance
	s_instance = [[XVim alloc] init];
	[s_instance parseRcFile];
    
    // Do the hooking after the App has finished launching,
    // Otherwise, we may miss some classes.
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: [XVim class]
                                  selector: @selector( hook )
                                   name: NSApplicationDidFinishLaunchingNotification
                                 object: nil];

    //The following codes helps reverse engineering the instance methods behaviour.
    //All the instance methods of a class passed to registerTracing are logged when they are called.
    //Since all the method calls an object of the class are logged
    //it has impact on the performance.
    //Comment out if you do not need to trace method calls of the specific classes or specify 
    // a class name in which you are interested in.

    //[Logger registerTracing:@"DVTSourceTextView"];
    //[Logger registerTracing:@"DVTTextFinder"];
    //[Logger registerTracing:@"DVTIncrementalFindBar"];
}

+ (void) hook
{
	[XVimSourceTextView hook];
	[XVimSourceCodeEditor hook];
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
        
        _yankRegister = nil;
        _recordingRegister = nil;
        _lastPlaybackRegister = nil;
        _repeatRegister = [_registers valueForKey:@"repeat"];
        
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
	[super dealloc];
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

- (void)onDeleteOrYank{
    // Don't do anything if we are recording into a register (that isn't the repeat register)
    if (self.recordingRegister != nil){
        return;
    }

    // If we are yanking into a specific register then we do not cycle through
    // the numbered registers.
    if (self.yankRegister != nil){
        [self.yankRegister clear];
        [self.yankRegister appendText:[[NSPasteboard generalPasteboard]stringForType:NSStringPboardType]];
    }else{
        // There are 10 numbered registers
        for (NSInteger i = self.numberedRegisters.count - 2; i >= 0; --i){
            XVimRegister *prev = [self.numberedRegisters objectAtIndex:i];
            XVimRegister *next = [self.numberedRegisters objectAtIndex:i+1];
            
            [next clear];
            [next appendText:prev.text];
        }
        
        XVimRegister *reg = [self.numberedRegisters objectAtIndex:0];
        [reg clear];
        [reg appendText:[[NSPasteboard generalPasteboard]stringForType:NSStringPboardType]];
    }
}

- (NSString*)pasteText{
    if (self.yankRegister != nil){
        TRACE_LOG(@"yankRegister: %@", self.yankRegister);
        return self.yankRegister.text;
    }
    
    return [[NSPasteboard generalPasteboard]stringForType:NSStringPboardType];
}

@end