//
//  DVTSourceTextViewHook.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/25/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "DVTSourceTextViewHook.h"
#import "Logger.h"
#import "XVimCommandLine.h"
#import "XVim.h"
@implementation DVTSourceTextViewHook

static NSMutableArray* queue;

+ (void)traceSuperViews:(NSView*)view{
    queue = [[[NSMutableArray alloc] init] autorelease];
    NSView* target = view;
    NSMutableString* str = [[NSMutableString alloc] init];
    
    // Going up to the topmost view
    while( target != nil ){
        [str appendFormat:@" <- %@",NSStringFromClass([target class])];
        target = [target superview];
    }
    TRACE_LOG(@"%@", str);
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    // New DVTSourceTextView is being created. (Remember that "self" is DVTSourceTextView object since this is hooked method )
    // What we do here is to create XVim object
    // which corresponds to this object
    // and set it as a (hidden) subview of this DVTSourceTextView.
    
    // Call original method
    [self XVimInitWithCoder:aDecoder];
    
    XVim* xvim = [[XVim alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)]; // XVim is dummy NSView object. This is not worked as a view. Just because to keep this object as subview in DVTSourceTextView 
    // Bind DVTSourceTextView and XVim object by tagging    
    xvim.tag = XVIM_TAG;
    [self addSubview:xvim];
    return self;
}

- (void)viewDidMoveToSuperview{
   XVim* xvim = [self viewWithTag:XVIM_TAG];
    if( nil != xvim ){
        TRACE_LOG(@"XVim object found");
        XVimCommandLine* cmdline = [[[XVimCommandLine alloc] init] autorelease];
        cmdline.xvim = xvim;
        xvim.cmdLine = cmdline; 
        xvim.sourceView = self;
        // Try to find parent scroll view
        NSScrollView* scrollView = [self enclosingScrollView]; // DVTSourceTextScrollView
        if( nil != scrollView ){
            
            [[scrollView contentView] setCopiesOnScroll:NO];
            // Add status bar in DVTSourceTextScrollView
            [scrollView addSubview:cmdline positioned:NSWindowAbove relativeTo:nil];
            // Observe DVTSourceScrollTextView notification
            [scrollView setPostsFrameChangedNotifications:YES];
            [[NSNotificationCenter defaultCenter] addObserver:cmdline selector:@selector(didFrameChanged:) name:NSViewFrameDidChangeNotification  object:scrollView];
        }else{
            ERROR_LOG(@"DVTSourceTExtScrollView not found.");
        }
    }else{
        ERROR_LOG(@"XVim object not found.");
    }
}

// Drawing Caret
- (void)_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
    XVim* xvim = [self viewWithTag:XVIM_TAG];
    if(MODE_INSERT == xvim.mode ){
        [self _XVimDrawInsertionPointInRect:aRect color:aColor];
    }else{
        [self drawInsertionPointInRect:aRect color:aColor turnedOn:YES];
    }
}

// Drawing Caret
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
    XVim* xvim = [self viewWithTag:XVIM_TAG];
    if(MODE_INSERT == xvim.mode ){
        [self XVimDrawInsertionPointInRect:rect color:color turnedOn:flag];
    }
    else{
        if(flag){
            color = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5];
            NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
            int glyphIndex = [[self layoutManager] glyphIndexForPoint:aPoint inTextContainer:[self textContainer]];
            NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[self textContainer]];
            
            [color set ];
            rect.size.width =rect.size.height/2;
            if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
                rect.size.width=glyphRect.size.width;
            NSRectFillUsingOperation( rect, NSCompositePlusDarker);
        } else {
            [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:NO];
        }
    }
}

- (BOOL) performKeyEquivalent:(NSEvent *)theEvent{
    METHOD_TRACE_LOG();
    XVim* xvim = [self viewWithTag:XVIM_TAG];
    unichar charcode = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    TRACE_LOG(@"keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ ASCII:%d", [theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
    BOOL done = NO;
    if( [[self window] firstResponder] != self){
        return NO;
    }
    if( MODE_NORMAL == xvim.mode ){
        switch(charcode){
            case 'u':
                if(theEvent.modifierFlags & NSControlKeyMask ){
                    [self pageUp:self];
                }
                else{
                    [[self undoManager] undo];
                }
                done = YES;
                break;
        }
    }else   if( MODE_VISUAL == xvim.mode ){
        switch(charcode){
            case 'u':
                if(theEvent.modifierFlags & NSControlKeyMask ){
                    [self pageUpAndModifySelection:self];
                }
                else{
                    [[self undoManager] undo];
                }
                done = YES;
                break;
        }
    }
    
    if( done )
        return YES;
    
    return [self XVimPerformKeyEquivalent:theEvent];
}

-  (void)keyDown:(NSEvent *)theEvent{
    XVim* xvim = [self viewWithTag:XVIM_TAG];
    if( nil == xvim ){
        [self XVimKeyDown:theEvent];
        return;
    }
    
    unichar charcode = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    [Logger logWithLevel:LogDebug format:@"Obj:%p keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self,[theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode];
    
    if( [xvim handleKeyEvent:theEvent] ){
        return;
    }
    // Call Original keyDown:
    [self XVimKeyDown:theEvent];
    return;
    
    
#if 0
    NSRange curPos = [self selectedRange];
    NSScrollView* scrollView = [self enclosingScrollView];
    if( MODE_NORMAL == xvim.mode ){
        switch(charcode){
            case 'i':    
                xvim.mode = MODE_INSERT;
                [xvim.commandBuf setString:@""];
                break;
            case 'I':
                [self moveToBeginningOfLine:self];
                xvim.mode = MODE_INSERT;
                [xvim.commandBuf setString:@""];
                break;
            case 'a':
                [self moveRight:self];
                xvim.mode = MODE_INSERT;
                [xvim.commandBuf setString:@""];
                break;
            case 'A':
                [self moveToEndOfLine:self];
                xvim.mode = MODE_INSERT;
                [xvim.commandBuf setString:@""];
                break;
            case 'j':
                [self moveDown: self];
                [xvim.commandBuf setString:@""];
                break;
            case 'k':
                [self moveUp: self];
                [xvim.commandBuf setString:@""];
                break;
            case 'h':
                [self moveLeft: self];
                [xvim.commandBuf setString:@""];
                break;
            case 'l':
                [self moveRight:self];
                [xvim.commandBuf setString:@""];
                break;
            case 'w':
                if( [xvim.commandBuf isEqualToString:@"d"] ){
                    [self moveWordForwardAndModifySelection:self];
                    [self cut:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [self moveWordForward: self];
                }
                break;
            case 'W':
                break;
            case 'b':
                if( [xvim.commandBuf isEqualToString:@"d"] ){
                    [self moveWordBackwardAndModifySelection:self];
                    [self cut:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [self moveWordBackward: self];
                }
                break;
            case 'g':
                if([xvim.commandBuf isEqualToString:@"d"] ){
                    /*
                    [self moveToBeginningOfDocumentAndModifySelection:self];
                    [self cut:self];
                     */
                }
                else if( [xvim.commandBuf isEqualToString:@""] ){
                    [xvim.commandBuf setString:@"g"];
                }
                else if([xvim.commandBuf isEqualToString:@"g"]){
                    [self moveToBeginningOfDocument:self];
                }
                else{
                    [xvim.commandBuf setString:@""];
                }
                break;
            case 'G':
                if( [xvim.commandBuf isEqualToString:@"d"] ){
                    [self moveToEndOfDocumentAndModifySelection:self];
                    [self cut:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [self moveToEndOfDocument:self];
                    [xvim.commandBuf setString:@""];
                }
                break;
            case '0':
                [self moveToBeginningOfLine: self];
                break;
            case 'x':
                [self moveForwardAndModifySelection:self];
                [self cut: self];
                
                break;
            case 'u':
                if(theEvent.modifierFlags & NSControlKeyMask){
                    [self pageUp:self];
                }
                else{
                    [[self undoManager] undo];
                }
                break;
            case 'd':
                if( theEvent.modifierFlags & NSControlKeyMask){
                    [self pageDown:self];
                    break;
                }
                else if( theEvent.modifierFlags & NSCommandKeyMask ){
                    // For Debug
                    [Logger traceViewInfo:[[[[[[self superview] superview] superview] superview] superview] superview] subView:YES];
                    //[Logger traceViewInfo:[NSApp view] subView:YES];
                    break;
                }
                else if( [xvim.commandBuf isEqualToString:@""] ){
                    NSRange r = [self selectedRange];
                    if( r.length != 0 ){
                        [self cut:self];
                    }else{
                        [xvim.commandBuf setString: @"d"];
                    }
                }else if( [xvim.commandBuf isEqualToString:@"d"] ){
                    
                    [self selectLine:self];
                    [self cut:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [xvim.commandBuf setString:@""];
                }
                break;
            case 'D':
                [self moveToEndOfLineAndModifySelection:self];
                [self cut:self];
                 [xvim.commandBuf setString:@""];
                break;
            case 'y':
                if( [xvim.commandBuf isEqualToString:@"y"] ){
                    [self selectLine:self];
                    [self copy:self];
                    [DVTSourceTextViewHook setSelectionRangeNone:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [xvim.commandBuf setString:@"y"];
                }
                break;
            case 'p':
                [self moveRight:self];
                [self pasteAsPlainText:self];
                [xvim.commandBuf setString:@""];
                break;
            case 'P':
                [self pasteAsPlainText:self];
                [xvim.commandBuf setString:@""];
                break;
            case 'r':
                if( [theEvent modifierFlags] & NSControlKeyMask ){
                    [[self undoManager] redo];
                }
                break;
            case '$':
                [self moveToEndOfLine:self];
                [xvim.commandBuf setString:@""];
                break;
            case 'O':
                if( [self _currentLineNumber] == 1 ){
                    [self moveToBeginningOfLine:self];
                    [self insertNewline:self];
                    [self moveUp:self];
                }
                else {
                    [self moveUp:self];
                    [self moveToEndOfLine:self];
                    [self insertNewline:self];
                }
                
                xvim.mode = MODE_INSERT;
                [xvim.commandBuf setString:@""];
                break;
            case 'o':
                [self moveToEndOfLine:self];
                [self insertNewline:self];
                xvim.mode = MODE_INSERT;
                [xvim.commandBuf setString:@""];
                break;
            case 'J':
                [self moveToEndOfLine:self];
                [self deleteForward:self];
                [self setSelectedRange:curPos];
                break;
            case 'v':
                xvim.mode = MODE_VISUAL;
                [xvim.commandBuf setString:@""];
                break;
            case 'V':
                xvim.mode = MODE_VISUAL;
                [self selectLine:self];
                [xvim.commandBuf setString:@""];
                break;
                break;
            case 'n':
                [xvim searchForward];
                break;
            case 'N':
                [xvim searchBackward];
                break;
            case '>':
                if( [xvim.commandBuf isEqualToString:@">"] ){
                    [self shiftRight:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [xvim.commandBuf setString:@">"];
                }
                break;
            case '<':
                if( [xvim.commandBuf isEqualToString:@"<"] ){
                    [self shiftLeft:self];
                    [xvim.commandBuf setString:@""];
                }else{
                    [xvim.commandBuf setString:@"<"];
                }
                break;
            case 27: // ESC
                [xvim.commandBuf setString:@""];
                break;
            case ':':
                [xvim commandModeWithFirstLetter:@":"];
                break;
            case '/':
                [xvim commandModeWithFirstLetter:@"/"];
                break;
            case 63232: // Arrow keys
            case 63233:
            case 63234:
            case 63235:
                [self XVimKeyDown:theEvent];
                break;
            default:
                [xvim.commandBuf setString:@""];
                break;
                
        }         
    }else if( MODE_INSERT == xvim.mode ){
        switch(charcode){
            case 27: // ESC
                xvim.mode = MODE_NORMAL;
                [DVTSourceTextViewHook setSelectionRangeNone:self];
                break;
            case '[':
                if( [theEvent modifierFlags] & NSControlKeyMask ){
                    xvim.mode = MODE_NORMAL;
                }
                else{
                    [self XVimKeyDown:theEvent];
                }
                break;
            case 'h':
                if( [theEvent modifierFlags] & NSControlKeyMask ){
                    [self deleteBackward:self];
                }
                else{
                    [self XVimKeyDown:theEvent];
                }
                break;
            default:
                [self XVimKeyDown:theEvent];
                break;
        }       
        
    }
    else if( MODE_CMDLINE == xvim.mode ){
        /*
        switch(charcode){
            case 27: // ESC
                xvim.mode = MODE_NORMAL;
                break;
        }
        if( 0x20 <= charcode && charcode <= 0x7e ){
            // Usual ASCII Letters and spaces
        }
         */
    }
    else if( MODE_VISUAL == xvim.mode ){
        switch(charcode){
            case 27: // ESC
                xvim.mode = MODE_NORMAL;
                [DVTSourceTextViewHook setSelectionRangeNone:self];
                break;
            case 'j':
                [self moveDownAndModifySelection: self];
                break;
            case 'k':
                [self moveUpAndModifySelection:self];
                break;
            case 'h':
                [self moveLeftAndModifySelection: self];
                break;
            case 'l':
                [self moveRightAndModifySelection: self];
                break;
            case 'w':
                [self moveWordForwardAndModifySelection: self];
                break;
            case 'b':
                [self moveWordBackwardAndModifySelection: self];
                break;
            case '0':
                [self moveToBeginningOfLineAndModifySelection: self];
                break;
            case '$':
                [self moveToEndOfLineAndModifySelection:self];
            case 'd':
                if( theEvent.modifierFlags & NSControlKeyMask ){
                    [self pageDownAndModifySelection:self];
                    break;
                }
                [self cut:self];
                xvim.mode = MODE_NORMAL;
                [DVTSourceTextViewHook setSelectionRangeNone:self];
                break;
            case 'y':
                if( [xvim.commandBuf isEqualToString:@""] ){
                    NSRange r = [self selectedRange];
                    [self copy:self];
                    xvim.mode = MODE_NORMAL;
                    r.length = 0;
                    [self setSelectedRange:r];
                }
                break;
            case 'p':
               [self pasteAsPlainText:self];
                xvim.mode = MODE_NORMAL;
                [DVTSourceTextViewHook setSelectionRangeNone:self];
                break;
            case '>':
                [self shiftRight:self];
                xvim.mode = MODE_NORMAL;
                [DVTSourceTextViewHook setSelectionRangeNone:self];
                break;
            case '<':
                 [self shiftLeft:self];
                xvim.mode = MODE_NORMAL;
                [DVTSourceTextViewHook setSelectionRangeNone:self];
                break;
            default:
                //[self XVimKeyDown:theEvent];
                break;
        } 
    }
    
    // Update Status Bar
    [xvim.statusBar setNeedsDisplay:YES];
#endif
}

- (void)doCommandBySelector:(SEL)aSelector{
    TRACE_LOG(@"SELECTOR : ", NSStringFromSelector(aSelector));
    [self XVimDoCommandBySelector:aSelector];
}



//Support Functions

+ (void)setSelectionRangeNone:(NSTextView*)view{
    NSRange r = [view selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
}




@end