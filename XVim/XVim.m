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
#import "XVimBuffer.h"
#import "Logger.h"
#import "XVimSearch.h"
#import "XVimExCommand.h"
#import "XVimKeymap.h"
#import "XVimRegister.h"
#import "XVimKeyStroke.h"
#import "XVimOptions.h"
#import "XVimHistoryHandler.h"
#import "XVimCommandLine.h"
#import "XVimMarks.h"
#import "XVimMotion.h"
#import "XVimTester.h"
#import "XVimUtil.h"
#import "IDEKit.h"
#import "objc/runtime.h"

NSString * const XVimBufferChangedNotification = @"XVimBufferChangedNotification";
NSString * const XVimEnabledStatusChangedNotification = @"XVimBufferEnableNotification";
NSString * const XVimBufferKey = @"XVimBufferKey";

@interface XVim() {
	XVimHistoryHandler *_exCommandHistory;
	XVimHistoryHandler *_searchHistory;
	XVimKeymap* _keymaps[XVIM_MODE_COUNT];
    NSFileHandle* _logFile;
}
@property (strong,nonatomic) XVimRegisterManager* registerManager;
@property (strong,nonatomic) XVimMutableString* lastOperationCommands;
@property (strong,nonatomic) XVimMutableString* tempRepeatRegister;
- (void)parseRcFile;
@end

@implementation XVim
@synthesize disabled = _disabled;
@synthesize options = _options;
@synthesize searcher = _searcher;
@synthesize lastCharacterSearchMotion = _lastCharacterSearchMotion;
@synthesize excmd = _excmd;
@synthesize marks = _marks;
@synthesize testRunner = _testRunner;
@synthesize registerManager = _registerManager;
@synthesize exCommandHistory = _exCommandHistory;
@synthesize searchHistory = _searchHistory;
@synthesize lastOperationCommands = _lastOperationCommands;
@synthesize isRepeating = _isRepeating;
@synthesize tempRepeatRegister = _tempRepeatRegister;
@synthesize lastPlaybackRegister = _lastPlaybackRegister;
@synthesize document = _document;
@synthesize isExecuting = _isExecuting;


// For reverse engineering purpose.
+(void)receiveNotification:(NSNotification*)notification{
    if( [notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"] ){
       TRACE_LOG(@"Got notification name : %@    object : %@", notification.name, NSStringFromClass([[notification object] class]));
    }
}

+ (void) addXVimMenu{
    // Add XVim menu
    // I have tried to add the item into "Editor" but did not work.
    // It looks that the initialization of "Editor" menu is done later...
    NSMenu* menu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem* item = [[[NSMenuItem alloc] init] autorelease];
    NSMenu* m = [[[NSMenu alloc] initWithTitle:@"XVim"] autorelease];
    [item setSubmenu:m];
    
    NSMenuItem* subitem = [[[NSMenuItem alloc] init] autorelease];
    subitem.title = @"Enable";
    [subitem setEnabled:YES];
    [subitem setState:NSOnState];
    subitem.target = [XVim instance];
    subitem.action = @selector(toggleXVim:);
    subitem.keyEquivalent = @"X";
    [m addItem:subitem];
    
    // Test cases
    if( [XVim instance].options.debug ){
        // Add category sub menu
        NSMenuItem* subm = [[[NSMenuItem alloc] init] autorelease];
        subm.title = @"Test categories";
        
        // Create category menu
        NSMenu* cat_menu = [[[NSMenu alloc] init] autorelease];
        // Menu for run all test
        NSMenuItem* subitem = [[[NSMenuItem alloc] init] autorelease];
        subitem.title = @"All";
        subitem.target = [XVim instance];
        subitem.action = @selector(runTest:);
        [cat_menu addItem:subitem];
        [cat_menu addItem:[NSMenuItem separatorItem]];
        for( NSString* c in [[XVim instance].testRunner categories]){
            subitem = [[[NSMenuItem alloc] init] autorelease];
            subitem.title = c;
            subitem.target = [XVim instance];
            subitem.action = @selector(runTest:);
            [subitem setEnabled:YES];
            [cat_menu addItem:subitem];
        }
        [m addItem:subm];
        [subm setSubmenu:cat_menu];
    }
    
    // Add XVim menu next to Editor menu
    NSInteger editorIndex = [menu indexOfItemWithTitle:@"Editor"];
    [menu insertItem:item atIndex:editorIndex];
    return;
    
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
    NSBundle* app = [NSBundle mainBundle];
    NSString* identifier = [app bundleIdentifier];
    
    // Load only into Xcode
    if( ![identifier isEqualToString:@"com.apple.dt.Xcode"] ){
        return;
    }
    
    // Entry Point of the Plugin.
    [Logger defaultLogger].level = LogTrace;

    // be sure XVim is initialized
    (void)[XVim instance];
    
    //Caution: parseRcFile can potentially invoke +instance on XVim (e.g. if "set ..." is
    //used in .ximvrc) so we must be sure to call it _AFTER_ +instance has completed
    [[XVim instance] parseRcFile];
    
    [self addXVimMenu];
    
    // This is for reverse engineering purpose. Comment this in and log all the notifications named "IDE" or "DVT"
    // [[NSNotificationCenter defaultCenter] addObserver:[XVim class] selector:@selector(receiveNotification:) name:nil object:nil];
    
    // Do the hooking after the App has finished launching,
    // Otherwise, we may miss some classes.

    // Command line window is not setuped if hook is too late.
    [XVimWindow class];
    
    // We used to observer NSApplicationDidFinishLaunchingNotification to wait for all the classes in Xcode are loaded.
    // When notification comes we hook some classes so that we do not miss any classes.
    // But unfortunately the notification often not delivered (I do not know why)
    // And as far as I test in Xcode 4.6 all the classes(frameworks/plugins) we requre to hook have loaded when this "load" method is called.
    // So we do not observer it now.
    // This is related to issue #12
    // If we need it again (waiting for some classes to be loaded) we probably should use NSBundleDidLoadNotification to know classes our interest
    // have loaded.
}

+ (XVim*)instance{
    static XVim *__instance = nil;
    static dispatch_once_t __once;
    
    dispatch_once(&__once, ^{
        // Allocate singleton instance
        __instance = [[XVim alloc] init];
        TRACE_LOG(@"XVim loaded");
    });
	return __instance;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id)init {
	if (self = [super init]) {
		self.options = [[[XVimOptions alloc] init] autorelease];
        _searchHistory = [[XVimHistoryHandler alloc] init];
        _searcher = [[XVimSearch alloc] init];
        _lastCharacterSearchMotion = nil;
        _marks = [[XVimMarks alloc] init];
        _testRunner= [[XVimTester alloc] init];
        
        self.excmd = [[[XVimExCommand alloc] init] autorelease];
        self.lastPlaybackRegister = nil;
        self.registerManager = [[[XVimRegisterManager alloc] init] autorelease];
        self.lastOperationCommands = [[[XVimMutableString alloc] init] autorelease];
        self.tempRepeatRegister = [[[XVimMutableString alloc] init] autorelease];
        self.isRepeating = NO;
        self.isExecuting = NO;
        _logFile = nil;
        _exCommandHistory = [[XVimHistoryHandler alloc] init];
        
        for (int i = 0; i < XVIM_MODE_COUNT; ++i) {
            _keymaps[i] = [[XVimKeymap alloc] init];
        }
        
        [_options addObserver:self forKeyPath:@"debug" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)dealloc{
    self.excmd = nil;
    self.registerManager = nil;
    self.lastOperationCommands = nil;
    self.lastPlaybackRegister = nil;
    self.lastOperationCommands = nil;
    self.tempRepeatRegister = nil;
    [_options release];
    [_searcher release];
    [_lastCharacterSearchMotion release];
    [_excmd release];
    [_logFile release];
    [_marks release];
    [_testRunner release];
    //[_info release];
    self.options = nil;
    
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"debug"]) {
        if( [[XVim instance] options].debug ){
            NSString *logPath = [@"~/.xvimlog" stringByExpandingTildeInPath];
            [[Logger defaultLogger] setLogFile:logPath];
        }else{
            [[Logger defaultLogger] setLogFile:nil];
        }
    } else if( [keyPath isEqualToString:@"document"] ){
        NSDocument *document = [object document];

        if (![document respondsToSelector:@selector(textStorage)]) {
            return;
        }

        NSTextStorage *textStorage = [[object document] textStorage];
        XVimBuffer *buffer = document.xvim_buffer;

        if (!buffer && [document.fileURL isFileURL]) {
            self.document = document.fileURL.path;
            buffer = [XVimBuffer makeBufferForDocument:document textStorage:textStorage];
        }
        if (buffer) {
            NSDictionary *userInfo = @{ XVimBufferKey: buffer };
            [[NSNotificationCenter defaultCenter] postNotificationName:XVimBufferChangedNotification object:nil userInfo:userInfo];
        }
    }
}
    
- (void)parseRcFile {
    NSString *keymapPath = [@"~/.xvimrc" stringByExpandingTildeInPath];
    NSString *keymapData = [[[NSString alloc] initWithContentsOfFile:keymapPath
                                                           encoding:NSUTF8StringEncoding
															  error:NULL] autorelease];
	for (NSString *string in [keymapData componentsSeparatedByString:@"\n"])
	{
		[self.excmd executeCommand:[@":" stringByAppendingString:string] inWindow:nil];
	}
}

- (void)writeToConsole:(NSString*)fmt, ...{
    
    [XVimLastActiveEditorArea() activateConsole:self];
    IDEConsoleArea* console = [(IDEDefaultDebugArea*)[XVimLastActiveEditorArea() activeDebuggerArea] consoleArea];
    
    // IDEConsoleArea has IDEConsoleTextView as its view but we do not have public method to access it.
    // It has the view as instance variable named "_consoleView"
    // So use obj-c runtime method to get instance varialbe by its name.
    IDEConsoleTextView* pView;
    object_getInstanceVariable(console , "_consoleView" , (void**)&pView);
    
    va_list argumentList;
    va_start(argumentList, fmt);
    NSString* string = [[[NSString alloc] initWithFormat:fmt arguments:argumentList] autorelease];
    pView.logMode = 1; // I do not know well about this value. But we have to set this to write text into the console.
    [pView insertText:string];
    [pView insertNewline:self];
    va_end(argumentList);
}

- (XVimKeymap*)keymapForMode:(XVIM_MODE)mode {
	return _keymaps[(int)mode];
}

- (XVimHistoryHandler*)exCommandHistory {
    return _exCommandHistory;
}

- (XVimHistoryHandler*)searchHistory {
	return _searchHistory;
}

- (void)appendOperationKeyStroke:(XVimString*)stroke{
    [self.tempRepeatRegister appendString:stroke];
}

- (void)fixOperationCommands{
    if( !self.isRepeating ){
        [self.lastOperationCommands setString:self.tempRepeatRegister];
        [self.tempRepeatRegister setString:@""];
    }
}

- (void)cancelOperationCommands{
    [self.tempRepeatRegister setString:@""];
}

- (void)startRepeat{
    self.isRepeating = YES;
}

- (void)endRepeat{
    self.isRepeating = NO;
}

- (void)ringBell {
    if (_options.errorbells) {
        NSBeep();
    }
    return;
}

- (void)runTest:(id)sender{
    NSMenuItem* m = sender;
    if( [m.title isEqualToString:@"All"] ){
        [self.testRunner selectCategories:self.testRunner.categories];
    }else{
        NSMutableArray* arr = [[[NSMutableArray alloc] init] autorelease];
        [arr addObject:m.title];
        [self.testRunner selectCategories:arr];
    }
    [self.testRunner runTest];
}

- (void)toggleXVim:(NSCell *)sender{
    if ([sender state] == NSOnState) {
        _disabled = YES;
        [sender setState:NSOffState];
    } else {
        _disabled = NO;
        [sender setState:NSOnState];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:XVimEnabledStatusChangedNotification
                                                        object:nil userInfo:nil];
}

@end
