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