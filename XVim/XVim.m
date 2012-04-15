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
@end

@implementation XVim
@synthesize registers = _registers;
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
		[[NSSet alloc] initWithObjects:
		 // 1. The unnamed register ""
		 [[XVimRegister alloc] initWithRegisterName:@"DQUOTE" displayName:@"\""],
		 // 2. 10 numbered registers "0 to "9 
		 [[XVimRegister alloc] initWithRegisterName:@"NUM0" displayName:@"0"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM1" displayName:@"1"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM2" displayName:@"2"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM3" displayName:@"3"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM4" displayName:@"4"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM5" displayName:@"5"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM6" displayName:@"6"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM7" displayName:@"7"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM8" displayName:@"8"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUM9" displayName:@"9"],
		 // 3. The small delete register "-
		 [[XVimRegister alloc] initWithRegisterName:@"DASH" displayName:@"-"],
		 // 4. 26 named registers "a to "z or "A to "Z
		 [[XVimRegister alloc] initWithRegisterName:@"a" displayName:@"a"],
		 [[XVimRegister alloc] initWithRegisterName:@"b" displayName:@"b"],
		 [[XVimRegister alloc] initWithRegisterName:@"c" displayName:@"c"],
		 [[XVimRegister alloc] initWithRegisterName:@"d" displayName:@"d"],
		 [[XVimRegister alloc] initWithRegisterName:@"e" displayName:@"e"],
		 [[XVimRegister alloc] initWithRegisterName:@"f" displayName:@"f"],
		 [[XVimRegister alloc] initWithRegisterName:@"g" displayName:@"g"],
		 [[XVimRegister alloc] initWithRegisterName:@"h" displayName:@"h"],
		 [[XVimRegister alloc] initWithRegisterName:@"i" displayName:@"i"],
		 [[XVimRegister alloc] initWithRegisterName:@"j" displayName:@"j"],
		 [[XVimRegister alloc] initWithRegisterName:@"k" displayName:@"k"],
		 [[XVimRegister alloc] initWithRegisterName:@"l" displayName:@"l"],
		 [[XVimRegister alloc] initWithRegisterName:@"m" displayName:@"m"],
		 [[XVimRegister alloc] initWithRegisterName:@"n" displayName:@"n"],
		 [[XVimRegister alloc] initWithRegisterName:@"o" displayName:@"o"],
		 [[XVimRegister alloc] initWithRegisterName:@"p" displayName:@"p"],
		 [[XVimRegister alloc] initWithRegisterName:@"q" displayName:@"q"],
		 [[XVimRegister alloc] initWithRegisterName:@"r" displayName:@"r"],
		 [[XVimRegister alloc] initWithRegisterName:@"s" displayName:@"s"],
		 [[XVimRegister alloc] initWithRegisterName:@"t" displayName:@"t"],
		 [[XVimRegister alloc] initWithRegisterName:@"u" displayName:@"u"],
		 [[XVimRegister alloc] initWithRegisterName:@"v" displayName:@"v"],
		 [[XVimRegister alloc] initWithRegisterName:@"w" displayName:@"w"],
		 [[XVimRegister alloc] initWithRegisterName:@"x" displayName:@"x"],
		 [[XVimRegister alloc] initWithRegisterName:@"y" displayName:@"y"],
		 [[XVimRegister alloc] initWithRegisterName:@"z" displayName:@"z"],
		 // 5. four read-only registers ":, "., "% and "#
		 [[XVimRegister alloc] initWithRegisterName:@"COLON" displayName:@":"],
		 [[XVimRegister alloc] initWithRegisterName:@"DOT" displayName:@"."],
		 [[XVimRegister alloc] initWithRegisterName:@"PERCENT" displayName:@"%"],
		 [[XVimRegister alloc] initWithRegisterName:@"NUMBER" displayName:@"#"],
		 // 6. the expression register "=
		 [[XVimRegister alloc] initWithRegisterName:@"EQUAL" displayName:@"="],
		 // 7. The selection and drop registers "*, "+ and "~  
		 [[XVimRegister alloc] initWithRegisterName:@"ASTERISK" displayName:@"*"],
		 [[XVimRegister alloc] initWithRegisterName:@"PLUS" displayName:@"+"],
		 [[XVimRegister alloc] initWithRegisterName:@"TILDE" displayName:@"~"],
		 // 8. The black hole register "_
		 [[XVimRegister alloc] initWithRegisterName:@"UNDERSCORE" displayName:@"_"],
		 // 9. Last search pattern register "/
		 [[XVimRegister alloc] initWithRegisterName:@"SLASH" displayName:@"/"],
		 // additional "hidden" register to store text for '.' command
		 [[XVimRegister alloc] initWithRegisterName:@"repeat" displayName:@"repeat"],
		 nil];
		
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
    return [self.registers member:[[XVimRegister alloc] initWithRegisterName:name displayName:@""]];
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

@end
