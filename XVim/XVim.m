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
#import "DVTSourceTextView.h"
#import "XVimSourceTextView.h"
#import "XVimSourceCodeEditor.h"
#import "XVimEvaluator.h"
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimNormalEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"

@interface XVim()
- (void)parseRcFile;
- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister;
@property (strong) NSString *searchCharacter;
@end

@implementation XVim
@synthesize tag,cmdLine,sourceView, dontCheckNewline;
@synthesize mode = _mode;
@synthesize registers = _registers;
@synthesize recordingRegister = _recordingRegister;
@synthesize handlingMouseClick = _handlingMouseClick;
@synthesize searchCharacter = _searchCharacter;
@synthesize shouldSearchCharacterBackward = _shouldSearchCharacterBackward;
@synthesize shouldSearchPreviousCharacter = _shouldSearchPreviousCharacter;
@synthesize searcher,excmd;
@synthesize options;

+ (void) load { 
    // Entry Point of the Plugin.
    // Hook methods ( mainly of DVTSourceTextView" )
    // The key method "initWithCoder:" and "keyDown:"
    // See the implementation in "DVTSourceTextViewHook.m" to know
    // what we are doing in these method hooks.
    
    [Logger defaultLogger].level = LogTrace;
    TRACE_LOG(@"XVim loaded");
    
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

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id) initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        _mode = MODE_NORMAL;
        tag = XVIM_TAG;
        _lastReplacementString = [[NSMutableString alloc] init];
        _lastReplacedString = [[NSMutableString alloc] init];
        _currentEvaluator = [[XVimNormalEvaluator alloc] init];
        [_currentEvaluator becameHandler:self];
        _localMarks = [[NSMutableDictionary alloc] init];
        excmd = [[XVimExCommand alloc] initWithXVim:self];
        searcher = [[XVimSearch alloc] initWithXVim:self];
        options = [[XVimOptions alloc] init];
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
        
        _recordingRegister = nil;
        _handlingMouseClick = NO;
        
        _searchCharacter = @"";
        _shouldSearchCharacterBackward = NO;
        _shouldSearchPreviousCharacter = NO;
		
		for (int i = 0; i < MODE_COUNT; ++i)
		{
			_keymaps[i] = [[XVimKeymap alloc] init];
		}
		[XVimKeyStroke initKeymaps];
		
		// Must be last since ex commands can use self
		[self parseRcFile];
    }
    
    return self;
}

-(void)dealloc{
    [_lastReplacedString release];
    [_lastReplacementString release];
    [options release];
    [searcher release];
    [excmd release];
    [XVimNormalEvaluator release];
	[super dealloc];
}

- (void)initializeOptions{
    // Implement later
}

- (void)setMode:(NSInteger)mode{
    _mode = mode;
}

- (XVimEvaluator*)currentEvaluator{
    return _currentEvaluator;
}

- (NSMutableDictionary *)getLocalMarks{
    return _localMarks;
}

- (NSString*)string{
    return [[self sourceView] string];
}

- (NSRange)selectedRange{
    return [[self sourceView] selectedRange];
}

- (void)parseRcFile {
    NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString *keymapPath = [homeDir stringByAppendingString: @"/.xvimrc"]; 
    NSString *keymapData = [[NSString alloc] initWithContentsOfFile:keymapPath 
                                                           encoding:NSUTF8StringEncoding
															  error:NULL];
	for (NSString *string in [keymapData componentsSeparatedByString:@"\n"])
	{
		[self.excmd executeCommand:[@":" stringByAppendingString:string]];
	}
}

- (XVimKeymap*)keymapForMode:(int)mode {
	return _keymaps[mode];
}

- (BOOL)handleKeyEvent:(NSEvent*)event{
	
	XVimKeyStroke* keyStroke = [XVimKeyStroke fromEvent:event];
	XVimKeymap* keymap = [_currentEvaluator selectKeymap:_keymaps];
	NSArray *keystrokes = [keymap lookupKeyStroke:keyStroke];
	
	for (XVimKeyStroke *keyStroke in keystrokes)
	{
		XVimEvaluator* nextEvaluator = [_currentEvaluator eval:keyStroke ofXVim:self];
		[self recordEvent:keyStroke intoRegister:_recordingRegister];
		[self recordEvent:keyStroke intoRegister:[self findRegister:@"repeat"]];
		if( nil == nextEvaluator ){
			nextEvaluator = [[XVimNormalEvaluator alloc] init];
		}
		
		if( _currentEvaluator != nextEvaluator ){
			[_currentEvaluator release];
			_currentEvaluator = nextEvaluator;
			
			XVIM_MODE newMode = [_currentEvaluator becameHandler:self];
			if (self.mode != MODE_CMDLINE){
				// Special case for cmdline mode. I don't like this, but
				// don't have time to refactor cmdline mode.
				self.mode = newMode;
			}
		}
	}
    
    [self.cmdLine setNeedsDisplay:YES];
    return YES;
}

// Should move to separated file.
- (void)commandDetermined:(NSString*)command{
    NSString* c = [command stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    DVTSourceTextView* srcView = (DVTSourceTextView*)[self superview]; // DVTTextSourceView
    TRACE_LOG(@"command : %@", c);
    if( [c length] == 0 ){
        // Something wrong
        ERROR_LOG(@"command string empty");
    }
    else if( [c characterAtIndex:0] == ':' ){
        [excmd executeCommand:c];
    }
    else if ([c characterAtIndex:0] == '/' || [c characterAtIndex:0] == '?') {
        NSRange found = [searcher executeSearch:c];
        //Move cursor and show the found string
        if( found.location != NSNotFound ){
            [srcView setSelectedRange:NSMakeRange(found.location, 0)];
            [srcView scrollToCursor];
            [srcView showFindIndicatorForRange:found];
        }else{
            [self statusMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchString] ringBell:TRUE];
        }
    }
   
    [[self window] makeFirstResponder:srcView]; // Since XVim is a subview of DVTSourceTextView;
    self.mode = MODE_NORMAL;
}

- (void)searchNext{
    NSTextView* srcView = (NSTextView*)[self superview]; // DVTTextSourceView
    NSRange found = [searcher searchNext];
    //Move cursor and show the found string
    if( found.location != NSNotFound ){
        [srcView setSelectedRange:NSMakeRange(found.location, 0)];
        [srcView scrollToCursor];
        [srcView showFindIndicatorForRange:found];
    }else{
        [self statusMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchString] ringBell:TRUE];
    }
}

- (void)searchPrevious{
    NSTextView* srcView = (NSTextView*)[self superview]; // DVTTextSourceView
    NSRange found = [searcher searchPrev];
    //Move cursor and show the found string
    if( found.location != NSNotFound ){
        [srcView setSelectedRange:NSMakeRange(found.location, 0)];
        [srcView scrollToCursor];
        [srcView showFindIndicatorForRange:found];
    }else{
        [self statusMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchString] ringBell:TRUE];
    }
}

- (void)setNextSearchBaseLocation:(NSUInteger)location{
    searcher.nextSearchBaseLocation = location;
}

- (void)setSearchCharacter:(NSString*)searchChar backward:(BOOL)backward previous:(BOOL)previous{
    self.searchCharacter = searchChar;
    _shouldSearchCharacterBackward = backward;
    _shouldSearchPreviousCharacter = previous;
}

- (NSUInteger)searchCharacterBackward:(NSUInteger)start{
    NSTextView *view = (NSTextView*)[self superview];
    NSString* s = [[view textStorage] string];
    NSRange at = NSMakeRange(start, 0); 
    if (at.location >= s.length-1) {
        return NSNotFound;
    }

    NSUInteger hol = [view headOfLine:at.location];
    if (hol == NSNotFound){
        return NSNotFound;
    }

    at.length = at.location - hol;
    at.location = hol;
    
    NSString* search_string = [s substringWithRange:at];
    NSRange found = [search_string rangeOfString:self.searchCharacter options:NSBackwardsSearch];
    if (found.location == NSNotFound){
        return NSNotFound;
    }

    NSUInteger location = at.location + found.location;
    if (self.shouldSearchPreviousCharacter){
        location += 1;
    }
    
    return location;
}

- (NSUInteger)searchCharacterForward:(NSUInteger)start{
    NSTextView *view = (NSTextView*)[self superview];
    NSString* s = [[view textStorage] string];
    NSRange at = NSMakeRange(start, 0); 
    if (at.location >= s.length-1) {
        return NSNotFound;
    }
    
    NSUInteger eol = [view endOfLine:at.location];
    if (eol == NSNotFound){
        return NSNotFound;
    }

    at.length = eol - at.location;
    if (at.location != eol) at.location += 1;
    
    NSString* search_string = [s substringWithRange:at];
    NSRange found = [search_string rangeOfString:self.searchCharacter];
    if (found.location == NSNotFound){
        return NSNotFound;
    }

    NSUInteger location = at.location + found.location;
    if (self.shouldSearchPreviousCharacter){
        location -= 1;
    }
    
    return location;
}

- (NSUInteger)searchCharacterNext:(NSUInteger)start{
    if(self.shouldSearchCharacterBackward){
        return [self searchCharacterBackward:start];
    }else{
        return [self searchCharacterForward:start];
    }
}

- (NSUInteger)searchCharacterPrevious:(NSUInteger)start{
    if(self.shouldSearchCharacterBackward){
        return [self searchCharacterForward:start];
    }else{
        return [self searchCharacterBackward:start];
    }
}

- (void)commandCanceled{
    METHOD_TRACE_LOG();
    self.mode = MODE_NORMAL;
    [[self window] makeFirstResponder:[self superview]]; // Since XVim is a subview of DVTSourceTextView;
}

- (void)commandModeWithFirstLetter:(NSString*)first{
    self.mode = MODE_CMDLINE;
    self.cmdLine.mode = MODE_STRINGS[self.mode];
    [self.cmdLine setFocusOnCommandWithFirstLetter:first];
}

- (NSString*)modeName{
    return MODE_STRINGS[self.mode];
}

- (void)ringBell {
    if ([self options].errorbells) {
        NSBeep();
    }
    return;
}

- (void)statusMessage:(NSString *)message ringBell:(BOOL)ringBell {
    // right now we ERROR_LOG the message
    // it should go into the status area before the MODE word and get cleared next time 
    // the mode changes ?
    ERROR_LOG("%@", message);
    if (ringBell) {
        [self ringBell];
    }
    return;
}

- (XVimRegister*)findRegister:(NSString*)name{
    return [self.registers member:[[XVimRegister alloc] initWithRegisterName:name displayName:@""]];
}

- (void)playbackRegister:(XVimRegister*)xregister withRepeatCount:(NSUInteger)count{
    [xregister playback:[self sourceView] withRepeatCount:count];
}

- (void)recordIntoRegister:(XVimRegister*)xregister{
    if (_recordingRegister == nil){
        _recordingRegister = xregister;
        self.cmdLine.additionalStatus = @"recording";
        // when you record into a register you clear out any previous recording
        // unless it was capitalized
        [_recordingRegister clear];
    }else{        
        [self ringBell];
    }
}

- (void)stopRecordingRegister:(XVimRegister*)xregister{
    if (_recordingRegister == nil){
        [self ringBell];
    }else{
        _recordingRegister = nil;
        self.cmdLine.additionalStatus = @"";
    }
}

- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister{
    switch ([_currentEvaluator shouldRecordEvent:keyStroke inRegister:xregister]) {
        case REGISTER_APPEND:
            [xregister appendKeyEvent:keyStroke];
            break;
            
        case REGISTER_REPLACE:
            [xregister clear];
            [xregister appendKeyEvent:keyStroke];
            break;
            
        case REGISTER_IGNORE:
        default:
            break;
    }
}

@end