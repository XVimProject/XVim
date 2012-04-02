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
#import "DVTSourceTextViewHook.h"
#import "XVimEvaluator.h"
#import "XVimNormalEvaluator.h"
#import "NSTextView+VimMotion.h"

@interface XVim()
- (void)recordEvent:(NSEvent*)event intoRegister:(XVimRegister*)xregister;
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
    Class c = NSClassFromString(@"DVTSourceTextView");
    
    // Hook setSelectedRange:
    [Hooker hookMethod:@selector(setSelectedRange:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(setSelectedRange:) ) keepingOriginalWith:@selector(XVimSetSelectedRange:)];
    
    // Hook setSelectedRange:affinity:stillSelecting:
    [Hooker hookMethod:@selector(setSelectedRange:affinity:stillSelecting:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(setSelectedRange:affinity:stillSelecting:) ) keepingOriginalWith:@selector(XVimSetSelectedRange:affinity:stillSelecting:)];
    
    // Hook initWithCoder:
    [Hooker hookMethod:@selector(initWithCoder:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(initWithCoder:) ) keepingOriginalWith:@selector(XVimInitWithCoder:)];
    
    // Hook viewDidMoveToSuperview
    [Hooker hookMethod:@selector(viewDidMoveToSuperview) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(viewDidMoveToSuperview) ) keepingOriginalWith:@selector(XVimViewDidMoveToSuperview)];
    
    // Hook keyDown:
    [Hooker hookMethod:@selector(keyDown:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(keyDown:) ) keepingOriginalWith:@selector(XVimKeyDown:)];   
    
    // Hook mouseDown:
    [Hooker hookMethod:@selector(mouseDown:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(mouseDown:) ) keepingOriginalWith:@selector(XVimMouseDown:)];

    // Hook mouseUp:
    [Hooker hookMethod:@selector(mouseUp:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(mouseUp:) ) keepingOriginalWith:@selector(XVimMouseUp:)];    

    // Hook drawRect:
    [Hooker hookMethod:@selector(drawRect:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(drawRect:)) keepingOriginalWith:@selector(XVimDrawRect:)];
    
    // Hook performKeyEquivalent:
    [Hooker hookMethod:@selector(performKeyEquivalent:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(performKeyEquivalent:)) keepingOriginalWith:@selector(XVimPerformKeyEquivalent:)];
    
    // Hook shouldDrawInsertionPoint for Drawing Caret
    [Hooker hookMethod:@selector(shouldDrawInsertionPoint) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(shouldDrawInsertionPoint)) keepingOriginalWith:@selector(XVimShouldDrawInsertionPoint)];
    
    // Hook drawInsertionPointInRect for Drawing Caret
    [Hooker hookMethod:@selector(drawInsertionPointInRect:color:turnedOn:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(drawInsertionPointInRect:color:turnedOn:)) keepingOriginalWith:@selector(XVimDrawInsertionPointInRect:color:turnedOn:)];
    
    // Hook _drawInsertionPointInRect for Drawing Caret       
    [Hooker hookMethod:@selector(_drawInsertionPointInRect:color:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(_drawInsertionPointInRect:color:)) keepingOriginalWith:@selector(_XVimDrawInsertionPointInRect:color:)];
    
    // Hook doCommandBySelector:
    [Hooker hookMethod:@selector(doCommandBySelector:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(doCommandBySelector:)) keepingOriginalWith:@selector(XVimDoCommandBySelector:)];
    
    // Hook didAddSubview of DVTSourceTextScrollView
    [Hooker hookMethod:@selector(didAddSubview:) ofClass:NSClassFromString(@"DVTSourceTextScrollView") withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(didAddSubview:)) keepingOriginalWith:@selector(XVimDidAddSubview:)];
    
    Class delegate = NSClassFromString(@"IDESourceCodeEditor");
        [Hooker hookMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) 
                   ofClass:delegate 
                withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)) 
       keepingOriginalWith:@selector(XVimTextView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
    
    [Hooker hookMethod:@selector(textViewDidChangeSelection:) 
               ofClass:delegate 
            withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(textViewDidChangeSelection:))
   keepingOriginalWith:@selector(XVimTextViewDidChangeSelection:)];
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id) initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        _mode = MODE_NORMAL;
        tag = XVIM_TAG;
        _lastSearchString = [[NSMutableString alloc] init];
        _lastReplacementString = [[NSMutableString alloc] init];
        _lastReplacedString = [[NSMutableString alloc] init];
        _nextSearchBaseLocation = 0;
        _searchBackword = NO;
        _wrapScan = TRUE; // :set wrapscan. TRUE is vi default
        _ignoreCase = FALSE; // :set ignorecase. FALSE is vi default
        _errorBells = FALSE; // ring bell on input errors.
        _currentEvaluator = [[XVimNormalEvaluator alloc] init];
        [_currentEvaluator becameHandler:self];
        _localMarks = [[NSMutableDictionary alloc] init];
        // From the vim documentation:
        // There are nine types of registers:
        // *registers* *E354*
        _registers =
        [[NSSet alloc] initWithObjects:
         // 1. The unnamed register ""
         [[XVimRegister alloc] initWithRegisterName:@"\""],
         // 2. 10 numbered registers "0 to "9 
         [[XVimRegister alloc] initWithRegisterName:@"0"],
         [[XVimRegister alloc] initWithRegisterName:@"1"],
         [[XVimRegister alloc] initWithRegisterName:@"2"],
         [[XVimRegister alloc] initWithRegisterName:@"3"],
         [[XVimRegister alloc] initWithRegisterName:@"4"],
         [[XVimRegister alloc] initWithRegisterName:@"5"],
         [[XVimRegister alloc] initWithRegisterName:@"6"],
         [[XVimRegister alloc] initWithRegisterName:@"7"],
         [[XVimRegister alloc] initWithRegisterName:@"8"],
         [[XVimRegister alloc] initWithRegisterName:@"9"],
         // 3. The small delete register "-
         [[XVimRegister alloc] initWithRegisterName:@"-"],
         // 4. 26 named registers "a to "z or "A to "Z
         [[XVimRegister alloc] initWithRegisterName:@"a"],
         [[XVimRegister alloc] initWithRegisterName:@"b"],
         [[XVimRegister alloc] initWithRegisterName:@"c"],
         [[XVimRegister alloc] initWithRegisterName:@"d"],
         [[XVimRegister alloc] initWithRegisterName:@"e"],
         [[XVimRegister alloc] initWithRegisterName:@"f"],
         [[XVimRegister alloc] initWithRegisterName:@"g"],
         [[XVimRegister alloc] initWithRegisterName:@"h"],
         [[XVimRegister alloc] initWithRegisterName:@"i"],
         [[XVimRegister alloc] initWithRegisterName:@"j"],
         [[XVimRegister alloc] initWithRegisterName:@"k"],
         [[XVimRegister alloc] initWithRegisterName:@"l"],
         [[XVimRegister alloc] initWithRegisterName:@"m"],
         [[XVimRegister alloc] initWithRegisterName:@"n"],
         [[XVimRegister alloc] initWithRegisterName:@"o"],
         [[XVimRegister alloc] initWithRegisterName:@"p"],
         [[XVimRegister alloc] initWithRegisterName:@"q"],
         [[XVimRegister alloc] initWithRegisterName:@"r"],
         [[XVimRegister alloc] initWithRegisterName:@"s"],
         [[XVimRegister alloc] initWithRegisterName:@"t"],
         [[XVimRegister alloc] initWithRegisterName:@"u"],
         [[XVimRegister alloc] initWithRegisterName:@"v"],
         [[XVimRegister alloc] initWithRegisterName:@"w"],
         [[XVimRegister alloc] initWithRegisterName:@"x"],
         [[XVimRegister alloc] initWithRegisterName:@"y"],
         [[XVimRegister alloc] initWithRegisterName:@"z"],
         // 5. four read-only registers ":, "., "% and "#
         [[XVimRegister alloc] initWithRegisterName:@":"],
         [[XVimRegister alloc] initWithRegisterName:@"."],
         [[XVimRegister alloc] initWithRegisterName:@"%"],
         [[XVimRegister alloc] initWithRegisterName:@"#"],
         // 6. the expression register "=
         [[XVimRegister alloc] initWithRegisterName:@"="],
         // 7. The selection and drop registers "*, "+ and "~  
         [[XVimRegister alloc] initWithRegisterName:@"*"],
         [[XVimRegister alloc] initWithRegisterName:@"+"],
         [[XVimRegister alloc] initWithRegisterName:@"~"],
         // 8. The black hole register "_
         [[XVimRegister alloc] initWithRegisterName:@"_"],
         // 9. Last search pattern register "/
         [[XVimRegister alloc] initWithRegisterName:@"/"],
         // additional "hidden" register to store text for '.' command
         [[XVimRegister alloc] initWithRegisterName:@"repeat"],
         nil];
        
        _recordingRegister = nil;
        _handlingMouseClick = NO;
        
        _searchCharacter = @"";
        _shouldSearchCharacterBackward = NO;
        _shouldSearchPreviousCharacter = NO;
    }
    
    return self;
}

-(void)dealloc{
    [_lastSearchString release];
    [_lastReplacedString release];
    [_lastReplacementString release];
    [XVimNormalEvaluator release];
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

- (BOOL)handleKeyEvent:(NSEvent*)event{
    XVimEvaluator* nextEvaluator = [_currentEvaluator eval:event ofXVim:self];
    [self recordEvent:event intoRegister:_recordingRegister];
    [self recordEvent:event intoRegister:[self findRegister:@"repeat"]];
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
    
    [self.cmdLine setNeedsDisplay:YES];
    return YES;
}

// Should move to separated file.
- (void)commandDetermined:(NSString*)command{
    NSString* c = [command stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSTextView* srcView = (NSTextView*)[self superview]; // DVTTextSourceView
    TRACE_LOG(@"command : %@", c);
    if( [c length] == 0 ){
        // Something wrong
        ERROR_LOG(@"command string empty");
    }
    else if( [c characterAtIndex:0] == ':' ){
        // ex commands (is it right?)
        NSString* ex_command;
        if( [c length] > 1 ){
            ex_command = [[c substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }else{
            ex_command = @"";
        }
        NSCharacterSet *words_cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray* words = [ex_command componentsSeparatedByCharactersInSet:words_cs];            
        NSUInteger words_count = [words count];
        int scanned_int_arg = -1;
        TRACE_LOG(@"EX COMMAND:%@, word count = %d", ex_command, words_count);

        // check to see if it's a simple ":NNN" ( go-line-NNN command )
        if ((words_count == 1) && [[NSScanner scannerWithString:[words objectAtIndex:0]] scanInt:&scanned_int_arg]) {
            // single arg that's a parsable int, go to line in scanned_int
            TRACE_LOG("go to line CMD line no = %d", scanned_int_arg);
            id mvid = nil; //seems to be ok to use nil for this for the movement calls we are doing
            if (scanned_int_arg > 0) {
                NSUInteger pos = [srcView positionAtLineNumber:scanned_int_arg column:0];
                NSUInteger pos_wo_space = [srcView nextNonBlankInALine:pos];
                if( NSNotFound == pos_wo_space ){
                    pos_wo_space = pos;
                }
                [srcView setSelectedRange:NSMakeRange(pos_wo_space,0)];
                [srcView scrollToCursor];
            }
            // TODO: This command must be treated as motion.
        }
        else if( [ex_command isEqualToString:@"w"] ){
            
            [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
        } 
        else if ([ex_command isEqualToString:@"wq"]) {
            [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
            [NSApp terminate:self];
        } 
        else if ([ex_command isEqualToString:@"q"]) {
            [NSApp terminate:self];
        }
        else if( [ex_command isEqualToString:@"bn"] ){
            // Dosen't work as I intend... This switches between tabs but the focus doesnt gose to the DVTSorceTextView after switching...
            // TODO: set first responder to the new DVTSourceTextView after switching tabs.
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:/*{*/@"}" charactersIgnoringModifiers:/*{*/@"}" isARepeat:NO keyCode:1];
            [[NSApplication sharedApplication] sendEvent:keyPress];
        }
        else if( [ex_command isEqualToString:@"bp"] ){
            // Dosen't work as I intend... This switches between tabs but the focus doesnt gose to the DVTSorceTextView after switching...
            // TODO: set first responder to the new DVTSourceTextView after switching tabs.
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"{"/*}*/ charactersIgnoringModifiers:@"{"/*}*/ isARepeat:NO keyCode:1];
            [[NSApplication sharedApplication] sendEvent:keyPress];
        }
        else if( [ex_command hasPrefix:@"se"] ){
            // vi users are used to doing ":se" as well as ":set"
            // after 25+ yrs, my fingers are trained to use ":se ic" or ":se noic" -MH
            NSString* arg0 = [words objectAtIndex:0];
            if( ([words count] > 1) && ([arg0 isEqualToString:@"se"] || [arg0 isEqualToString:@"set"]) ){
                NSString* setCommand = [words objectAtIndex:1];
                if( [setCommand isEqualToString:@"wrap"] ){
                    [srcView setWrapsLines:YES];
                }
                else if( [setCommand isEqualToString:@"nowrap"] ){
                    [srcView setWrapsLines:NO];
                }                
                else if( [setCommand isEqualToString:@"ignorecase"] || [setCommand isEqualToString:@"ic"] ){
                    _ignoreCase = TRUE;
                }                
                else if( [setCommand isEqualToString:@"noignorecase"] || [setCommand isEqualToString:@"noic"] ){
                    _ignoreCase = FALSE;
                }            
                else if( [setCommand isEqualToString:@"wrapscan"] || [setCommand isEqualToString:@"ws"] ){
                    _wrapScan = TRUE;
                }                
                else if( [setCommand isEqualToString:@"nowrapscan"] || [setCommand isEqualToString:@"nows"] ){
                    _wrapScan = FALSE;
                }            
                else if( [setCommand isEqualToString:@"errorbells"] || [setCommand isEqualToString:@"eb"] ){
                    _errorBells= TRUE;
                }            
                else if( [setCommand isEqualToString:@"noerrorbells"] || [setCommand isEqualToString:@"noeb"] ){
                    _errorBells= FALSE;
                }            

                else {
                    TRACE_LOG("Don't recognize '%@' sub command for ex_command line %@", setCommand, ex_command);
                }
            }
        }
        else if( [ex_command hasPrefix:@"!"] ){
            
        }
        else if( [ex_command isEqualToString:@"debug"] ){
           // Place Any debugging purpose process...
            [[self superview] setSelectedRange:NSMakeRange([[[self superview] string] length], 0)];
        }
        else if( [ex_command isEqualToString:@"make"] ){
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"b" charactersIgnoringModifiers:@"b" isARepeat:NO keyCode:1];
            [[NSApplication sharedApplication] sendEvent:keyPress];
        }
        else if( [ex_command isEqualToString:@"run"] ){
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"r" charactersIgnoringModifiers:@"r" isARepeat:NO keyCode:1];
            [[NSApplication sharedApplication] sendEvent:keyPress];
        }
        else if( [ex_command isEqualToString:@"reg"] ){
            TRACE_LOG(@"registers: %@", self.registers);
        }
        else if( [ex_command hasPrefix:@"%s/"] ) {
            // Split the string into the various components
            NSString* replaced = @"";
            NSString* replacement = @"";
            char previous = 0;
            int component = 0;
            BOOL global = NO;
            BOOL confirmation = NO;
            if ([ex_command length] >= 3) {
                for(int i=3;i<[ex_command length];++i) {
                    char current = [ex_command characterAtIndex:i];
                    if (current == '/' && previous != '\\') {
                        component++;
                    } else {
                        if (component == 0) {
                            replaced = [NSString stringWithFormat:@"%@%c",replaced,current];
                        } else if (component == 1) {
                            replacement = [NSString stringWithFormat:@"%@%c",replacement,current];
                        } else {
                            if (current == 'g') {
                                global = YES;
                            } else if (current == 'c') {
                                confirmation = YES;
                            } else {
                                ERROR_LOG("Unknown replace option %c",current);
                            }
                        }
                        previous = current;
                    }
                }
                TRACE_LOG("replaced=%@",replaced);
                TRACE_LOG("replacement=%@",replacement);
            }
            [_lastReplacedString setString:replaced];
            [_lastReplacementString setString:replacement];
            // Replace all the occurrences
            _nextReplaceBaseLocation = 0;
            int numReplacements = 0;
            BOOL found;
            do {
                found = [self replaceForward];
                if (found) {
                    numReplacements++;
                }
            } while(found && global);
            [self statusMessage:[NSString stringWithFormat:
                                 @"Number of occurrences replaced %d",numReplacements] ringBell:TRUE];
        }
        else {
            TRACE_LOG("Don't recognize ex_command %@", ex_command);
        }
    }
    else if ([c characterAtIndex:0] == '/' || [c characterAtIndex:0] == '?') {
        // note: c is the whitespace trimmed version of command.
        // we want the non trimmed version (command) because leading/trailing
        // whitespace is something should be part of the search string
        if ([command characterAtIndex:0] == '?') {
            _searchBackword = YES;
        } else {
            _searchBackword = NO;
        }
        if([command length] == 1) {
            // in vi, if there's no search string. use the last one specified. like you do for 'n'
            // just set the direction of the search
            [self searchNext];
        }
        else if([command length] > 1) {
            NSString *s = [command substringFromIndex:1];
            [_lastSearchString setString: s];
            [self searchNext];
        }
    }
    
    [[self window] makeFirstResponder:srcView]; // Since XVim is a subview of DVTSourceTextView;
    self.mode = MODE_NORMAL;
}

- (void)searchForward {
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
    
    NSTextView* srcView = [self superview];
    NSUInteger search_base = [self getNextSearchBaseLocation];
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_ignoreCase == TRUE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
        regularExpressionWithPattern:_lastSearchString
        options:r_opts
        error:&error];
        
    if (error != nil) {
        [self statusMessage:[NSString stringWithFormat:
            @"Cannot compile regular expression '%@'",_lastSearchString] ringBell:TRUE];
        return;
    }
    
    // search text beyond the search_base
    if( [[srcView string] length]-1 > search_base){
        found = [regex rangeOfFirstMatchInString:[srcView string] 
            options:r_opts
            range:NSMakeRange(search_base+1, [[srcView string] length] - search_base - 1)];
    }
    
    // if wrapscan is on, wrap to the top and search
    if (found.location == NSNotFound && _wrapScan == TRUE) {
        found = [regex rangeOfFirstMatchInString:[srcView string] 
            options:r_opts
            range:NSMakeRange(0, [[srcView string] length])];
        [self statusMessage:[NSString stringWithFormat:
            @"Search wrapped for '%@'",_lastSearchString] ringBell:TRUE];
    }
    if( found.location != NSNotFound ){
        //Move cursor and show the found string
        [srcView setSelectedRange:NSMakeRange(found.location, 0)];
        [srcView scrollToCursor];
        [srcView showFindIndicatorForRange:found];
        // note: make sure this stays *after* setSelectedRange which also updates 
        // _nextSearchBaseLocation as a side effect
        [self setNextSearchBaseLocation:found.location + ((found.length==0)? 0: found.length-1)];
    } else {
        [self statusMessage:[NSString stringWithFormat:
            @"Cannot find '%@'",_lastSearchString] ringBell:TRUE];
    }
}


- (void)searchBackward {
    // opts = (NSBackwardsSearch | NSRegularExpressionSearch) is not supported by [NSString rangeOfString:opts]
    // What we do instead is a search for all occurences and then
    // use the range of the last match. Not very efficient, but i don't think
    // optimization is warranted until slowness is experienced at the user level.
    NSTextView* srcView = [self superview];
    NSUInteger search_base = [self getNextSearchBaseLocation];
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_ignoreCase == TRUE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
     
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
        regularExpressionWithPattern:_lastSearchString
        options:r_opts
        error:&error];
        
    if (error != nil) {
        [self statusMessage:[NSString stringWithFormat:
            @"Cannot compile regular expression '%@'",_lastSearchString] ringBell:TRUE];
        return;
    }
    
    NSArray*  matches = [regex matchesInString:[srcView string]
        options:r_opts
        range:NSMakeRange(0, [[srcView string] length]-1)];
        
    // search above base
    if (search_base > 0) {
        for (NSTextCheckingResult *match in matches) { // get last match in area before search_base
            NSRange tmp = [match range];
            if (tmp.location >= search_base)
                break;
            found = tmp;
        }
    }
    // if wrapscan is on, search below base as well
    if (found.location == NSNotFound && _wrapScan == TRUE) {
        if ([matches count] > 0) {
            NSTextCheckingResult *match = ([matches objectAtIndex:[matches count]-1]);
            found = [match range];
            [self statusMessage:[NSString stringWithFormat:
                @"Search wrapped for '%@'",_lastSearchString] ringBell:FALSE];
        }
    }
    if (found.location != NSNotFound) {
        // Move cursor and show the found string
        [srcView setSelectedRange:NSMakeRange(found.location, 0)];
        [srcView scrollToCursor];
        [srcView showFindIndicatorForRange:found];
        // note: make sure this stays *after* setSelectedRange which also updates 
        // _nextSearchBaseLocation as a side effect
        [self setNextSearchBaseLocation:found.location]; // demonstrative. not really needed
    } else {
        [self statusMessage:[NSString stringWithFormat:
            @"Cannot find '%@'",_lastSearchString] ringBell:TRUE];
    }
}


- (void)searchNext{
    if( _searchBackword){
        [self searchBackward];
    }else{
        [self searchForward];
    }
    return;
 }

- (void)searchPrevious{
    if( _searchBackword){
        [self searchForward];
    }else{
        [self searchBackward];
    }
    return;
}

- (void)setSearchCharacter:(NSString*)searchChar backward:(BOOL)backward previous:(BOOL)previous{
    self.searchCharacter = searchChar;
    _shouldSearchCharacterBackward = backward;
    _shouldSearchPreviousCharacter = previous;
}

- (NSUInteger)searchCharacterBackward:(NSUInteger)start{
    NSTextView *view = [self superview];
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
    NSTextView *view = [self superview];
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

- (BOOL)replaceForward {
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
    
    NSTextView* srcView = [self superview];
    NSUInteger search_base = _nextReplaceBaseLocation;
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_ignoreCase == TRUE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
                                  regularExpressionWithPattern:_lastReplacedString
                                  options:r_opts
                                  error:&error];
    
    if (error != nil) {
        [self statusMessage:[NSString stringWithFormat:
                             @"Cannot compile regular expression '%@'",_lastSearchString] ringBell:TRUE];
        return NO;
    }
    
    // search text beyond the search_base
    if( [[srcView string] length]-1 > search_base){
        found = [regex rangeOfFirstMatchInString:[srcView string] 
                                         options:r_opts
                                           range:NSMakeRange(search_base+1, [[srcView string] length] - search_base - 1)];
    }
    
    if( found.location != NSNotFound ){
        //Move cursor and show the found string
        [srcView scrollRangeToVisible:found];
        //[srcView showFindIndicatorForRange:found];
        //[srcView setSelectedRange:NSMakeRange(found.location, 0)];
        
        // Replace the text
        [[srcView textStorage] replaceCharactersInRange:found withString:_lastReplacementString];
        
        _nextReplaceBaseLocation = found.location + ((found.length==0)? 0: found.length-1);
        return YES;
    } else {
        return NO;
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
    if (_errorBells) {
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

- (void)setNextSearchBaseLocation:(NSUInteger)location {
    _nextSearchBaseLocation = location;
}
- (NSUInteger)getNextSearchBaseLocation {
    return _nextSearchBaseLocation;
}

- (XVimRegister*)findRegister:(NSString*)name{
    return [self.registers member:[[XVimRegister alloc] initWithRegisterName:name]];
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

- (void)recordEvent:(NSEvent*)event intoRegister:(XVimRegister*)xregister{
    switch ([_currentEvaluator shouldRecordEvent:event inRegister:xregister]) {
        case REGISTER_APPEND:
            [xregister appendKeyEvent:event];
            break;
            
        case REGISTER_REPLACE:
            [xregister clear];
            [xregister appendKeyEvent:event];
            break;
            
        case REGISTER_IGNORE:
        default:
            break;
    }
}

@end
