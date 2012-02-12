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

#import "Logger.h"
#import "Hooker.h"
#import "DVTSourceTextViewHook.h"
#import "XVimEvaluator.h"

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
 
    //The foloowing codes helps reverse engineering the instance methods behaviour.
    //All the instance methods of a class passed to registerTracing are logged when they are called.
    //Since all the method calls an object of the class are logged
    //it has impact on the performance.
    //Comment out if you do not need to trace method calls of the specific classes or specify 
    // a class name in which you are interested in.

    //[Logger registerTracing:@"DVTSourceTextView"];
    //[Logger registerTracing:@"DVTTextFinder"];
    //[Logger registerTracing:@"DVTIncrementalFindBar"];
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
        _currentEvaluator = [[XVimNormalEvaluator alloc] init];
    }
    
    return self;
}

-(void)dealloc{
    [_lastSearchString release];
    [XVimNormalEvaluator release];
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
        TRACE_LOG(@"EX COMMAND:%@", ex_command);
        if( [ex_command isEqualToString:@"w"] ){
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
        else if( [ex_command hasPrefix:@"set"] ){
            if( [ex_command length] > 3 ){
                NSString* setCommand = [[c substringFromIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if( [setCommand isEqualToString:@"wrap"] ){
                    [srcView setWrapsLines:YES];
                }
                else if( [setCommand isEqualToString:@"nowrap"] ){
                    [srcView setWrapsLines:NO];
                }
            }
        }
        else if( [ex_command hasPrefix:@"!"] ){
            
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
        NSRange found = [[srcView string] rangeOfString:_lastSearchString options:NSCaseInsensitiveSearch range:NSMakeRange(r.location+1, [[srcView string] length] - r.location - 1)];
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
        NSRange found = [[srcView string] rangeOfString:_lastSearchString options:NSBackwardsSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, r.location-1)];
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

@end