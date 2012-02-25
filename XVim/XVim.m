//
//  XVim.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVim.h"


// HOW TO INSTALL
// Copy XVim.dylib to ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins
//                    (Make directory if it does not exist)

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


@implementation XVim
@synthesize tag,mode,cmdLine,sourceView;

+ (void) load { 
    // Entry Point of the Plugin.
    // Hook methods ( mainly of DVTSourceTextView" )
    // The key method "initWithCoder:" and "keyDown:"
    // See the implementation in "DVTSourceTextViewHook.m" to know
    // what we are doing in these method hooks.
    
    [Logger defaultLogger].level = LogTrace;
    
    TRACE_LOG(@"XVim loaded");
    Class c = NSClassFromString(@"DVTSourceTextView");
    
    // Hook initWithCoder:
    [Hooker hookMethod:@selector(initWithCoder:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(initWithCoder:) ) keepingOriginalWith:@selector(XVimInitWithCoder:)];
    
    // Hook viewDidMoveToSuperview
    [Hooker hookMethod:@selector(viewDidMoveToSuperview) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(viewDidMoveToSuperview) ) keepingOriginalWith:@selector(XVimViewDidMoveToSuperview)];

    // Hook keyDown:
    [Hooker hookMethod:@selector(keyDown:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(keyDown:) ) keepingOriginalWith:@selector(XVimKeyDown:)];   

    // Hook performKeyEquivalent:
    [Hooker hookMethod:@selector(performKeyEquivalent:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(performKeyEquivalent:)) keepingOriginalWith:@selector(XVimPerformKeyEquivalent:)];
    
    // Hook drawInsertionPointInRect for Drawing Caret
    [Hooker hookMethod:@selector(drawInsertionPointInRect:color:turnedOn:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(drawInsertionPointInRect:color:turnedOn:)) keepingOriginalWith:@selector(XVimDrawInsertionPointInRect:color:turnedOn:)];
   
    // Hook _drawInsertionPointInRect for Drawing Caret       
    [Hooker hookMethod:@selector(_drawInsertionPointInRect:color:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(_drawInsertionPointInRect:color:)) keepingOriginalWith:@selector(_XVimDrawInsertionPointInRect:color:)];
    
    // Hook doCommandBySelector:
    [Hooker hookMethod:@selector(doCommandBySelector:) ofClass:c withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(doCommandBySelector:)) keepingOriginalWith:@selector(XVimDoCommandBySelector:)];
    
    // Hook didAddSubview of DVTSourceTextScrollView
    [Hooker hookMethod:@selector(didAddSubview:) ofClass:NSClassFromString(@"DVTSourceTextScrollView") withMethod:class_getInstanceMethod([DVTSourceTextViewHook class], @selector(didAddSubview:)) keepingOriginalWith:@selector(XVimDidAddSubview:)];
 
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

+ (void)initialize
{

    return;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id) initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        mode = MODE_NORMAL;
        tag = XVIM_TAG;
        _lastSearchString = [[NSMutableString alloc] init];
        
        _searchBackword = NO;
        _wrapScan = TRUE; // :set wrapscan. TRUE is vi default
        _ignoreCase = FALSE; // :set ignorecase. FALSE is vi default
        _errorBells = FALSE; // ring bell on input errors.
        _currentEvaluator = [[XVimNormalEvaluator alloc] init];
        _localMarks = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(void)dealloc{
    [_lastSearchString release];
    [XVimNormalEvaluator release];
}

- (NSMutableDictionary *)getLocalMarks{
    return _localMarks;
}

- (BOOL)handleKeyEvent:(NSEvent*)event{
    XVimEvaluator* nextEvaluator = [_currentEvaluator eval:event ofXVim:self];     
    if( nil == nextEvaluator ){
        [_currentEvaluator release];
        _currentEvaluator = [[XVimNormalEvaluator alloc] init];
    }else{
        _currentEvaluator = nextEvaluator;
    }
    NSRange r = [[self sourceView] selectedRange];
    TRACE_LOG(@"SelectedRange: loc:%d len:%d", r.location, r.length);
    [self.cmdLine setNeedsDisplay:YES];
    return YES;
}

- (void)commandDetermined:(NSString*)command{
    NSString* c = [command stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSTextView* srcView = [self superview]; // DVTTextSourceView
    TRACE_LOG(@"command : %@", c);
    if( [c length] == 0 ){
        // Something wroing
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
                [srcView moveToBeginningOfDocument:mvid];
                // move to line 'scanned_int_arg'
                for( int i = 1; i < scanned_int_arg; i++ ){ // TODO: there is probabaly a more efficient way to do this
                    [srcView moveDown:mvid]; 
                }
                // move to first non whitespace char in line
                [srcView moveToBeginningOfLine:mvid];
                NSMutableString* s = [[srcView textStorage] mutableString];
                NSRange end = [srcView selectedRange];
                for (NSUInteger idx = end.location; idx < s.length; idx++) {
                    if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
                        break;
                    [srcView moveRight:mvid];
                }
            }
        }
        else if( [ex_command isEqualToString:@"w"] ){
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"s" charactersIgnoringModifiers:@"s" isARepeat:NO keyCode:1];
            [[NSApplication sharedApplication] sendEvent:keyPress];
        }
        else if( [ex_command isEqualToString:@"bn"] ){
            // Dosen't work as I intend... This switches between tabs but the focus doesnt gose to the DVTSorceTextView after switching...
            // TODO: set first responder to the new DVTSourceTextView after switching tabs.
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"}" charactersIgnoringModifiers:@"}" isARepeat:NO keyCode:1];
            [[NSApplication sharedApplication] sendEvent:keyPress];
        }
        else if( [ex_command isEqualToString:@"bp"] ){
            // Dosen't work as I intend... This switches between tabs but the focus doesnt gose to the DVTSorceTextView after switching...
            // TODO: set first responder to the new DVTSourceTextView after switching tabs.
            NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
            NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"{" charactersIgnoringModifiers:@"{" isARepeat:NO keyCode:1];
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
        else {
            TRACE_LOG("Don't recognize ex_command %@", ex_command);
        }
    }
    else if( [c characterAtIndex:0] == '/' ){
        // search
        _searchBackword = NO;
        if( [c length] > 1 ){
            [_lastSearchString setString: [[c substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            // I think there should be better solution to handle search action by using XCode features...
            [self searchNext];
        }
    }
    else if( [c characterAtIndex:0] == '?' ){
        _searchBackword = YES;
        if( [c length] > 1 ){
            [_lastSearchString setString: [[c substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            [self searchNext];
        }
    }
    
    [[self window] makeFirstResponder:srcView]; // Since XVim is a subview of DVTSourceTextView;
    mode = MODE_NORMAL;
}

- (void)searchForward{
    NSTextView* srcView = [self superview];
    // get current insert position
    NSRange r = [srcView selectedRange];
    
    // search text from the index
    if( [[srcView string] length]-1 > r.location ){
        NSRange found = [[srcView string] 
             rangeOfString:_lastSearchString 
             options:((_ignoreCase == TRUE) ? NSCaseInsensitiveSearch : NSLiteralSearch) 
             range:NSMakeRange(r.location+1, [[srcView string] length] - r.location - 1)];
        
        // if wrapscan is on, wrap to the top and try again
        if (found.location == NSNotFound && _wrapScan == TRUE) {
            // TBD: vi usually puts something around the NORMAL|INSERT status msg is that says "scan wrapped"
            found = [[srcView string] 
                rangeOfString:_lastSearchString 
                options:((_ignoreCase == TRUE) ? NSCaseInsensitiveSearch : NSLiteralSearch) 
                range:NSMakeRange(0, [[srcView string] length])];
        }
        
        if( found.location != NSNotFound ){
            //Move cursor and show the found string
            [srcView scrollRangeToVisible:found];
            [srcView showFindIndicatorForRange:found];
            [srcView setSelectedRange:NSMakeRange(found.location, 0)];
        }
    }

}


- (void)searchBackward{
    NSTextView* srcView = [self superview];
    // get current insert position
    NSRange r = [srcView selectedRange];
    
    // search text from the index
    if( r.location > 0 ){
        NSRange found = [[srcView string] 
            rangeOfString:_lastSearchString 
            options:NSBackwardsSearch|((_ignoreCase == TRUE) ? NSCaseInsensitiveSearch : NSLiteralSearch)
            range:NSMakeRange(0, r.location-1)];
        
        // if wrapscan is on, wrap to the top and try again
        if (found.location == NSNotFound && _wrapScan == TRUE) {
            // TBD: vi usually puts something around the NORMAL|INSERT status msg is that says "scan wrapped"
            found = [[srcView string] 
                     rangeOfString:_lastSearchString 
                     options:NSBackwardsSearch|((_ignoreCase == TRUE) ? NSCaseInsensitiveSearch : NSLiteralSearch) 
                     range:NSMakeRange(0, [[srcView string] length])];
        }
        
        if( found.location != NSNotFound ){
            //Move cursor and show the found string
            [srcView scrollRangeToVisible:found];
            [srcView showFindIndicatorForRange:found];
            [srcView setSelectedRange:NSMakeRange(found.location, 0)];
        }
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

- (void)commandCanceled{
    METHOD_TRACE_LOG();
    mode = MODE_NORMAL;
    [[self window] makeFirstResponder:[self superview]]; // Since XVim is a subview of DVTSourceTextView;
}

- (void)commandModeWithFirstLetter:(NSString*)first{
    mode = MODE_CMDLINE;
    [self cmdLine].mode = MODE_STRINGS[mode];
    [[self cmdLine] setFocusOnCommandWithFirstLetter:first];
}

- (NSString*)modeName{
    return MODE_STRINGS[self.mode];
}

- (NSRange)wordForward:(NSTextView *)view begin:(NSRange)begin{

}


- (void)ringBell {
    if (_errorBells) {
        NSBeep();
    }
    return;
}
- (void)statusMessage:(NSString *)message ringBell:(BOOL)ringBell {
    // right now we don't do anything w/ the message
    // it should go into the status area before the MODE word and get cleared next time 
    // the mode changes ?
    if (ringBell) {
        [self ringBell];
    }
    return;
}
@end
