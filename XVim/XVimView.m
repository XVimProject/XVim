//
//  XVimView.m
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <objc/runtime.h>
#import "XVim.h"
#import "XVimView.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "NSObject+XVimAdditions.h"
#import "NSTextView+VimOperation.h"
#import "XVimOptions.h"
#import "XVimSearch.h"

static char const * const XVIM_KEY_VIEW = "xvim_view";

@implementation NSTextView (XVimView)

+ (void)xvim_initialize
{
    if (self == [NSTextView class]) {
        DEBUG_LOG("Swizzling NSTextView");

#define swizzle(sel) \
        [self xvim_swizzleInstanceMethod:@selector(sel) with:@selector(xvim_##sel)]

        swizzle(dealloc);

        swizzle(setSelectedRanges:affinity:stillSelecting:);
        swizzle(selectAll:);
        swizzle(paste:);
        swizzle(delete:);
        swizzle(keyDown:);
        swizzle(mouseDown:);
        swizzle(drawRect:);
        swizzle(_drawInsertionPointInRect:color:);
        swizzle(drawInsertionPointInRect:color:turnedOn:);
        swizzle(didChangeText);
        swizzle(viewDidMoveToSuperview);
        swizzle(observeValueForKeyPath:ofObject:change:context:);
    }

#undef swizzle
}

- (XVimView *)xvim_view
{
    return objc_getAssociatedObject(self, XVIM_KEY_VIEW);
}

- (XVimView *)xvim_makeXVimViewInWindow:(XVimWindow *)window
{
    return [[[XVimView alloc] initWithView:self window:window] autorelease];
}

- (void)xvim_setupForXVimView:(XVimView *)view
{
    if (!self.xvim_view) {
        [XVim.instance.options addObserver:self forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.options addObserver:self forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.searcher addObserver:self forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    objc_setAssociatedObject(self, XVIM_KEY_VIEW, view, OBJC_ASSOCIATION_RETAIN);
}

- (void)xvim_dealloc
{
    if (self.xvim_view) {
        @try {
            [XVim.instance.options removeObserver:self forKeyPath:@"hlsearch"];
            [XVim.instance.options removeObserver:self forKeyPath:@"ignorecase"];
            [XVim.instance.searcher removeObserver:self forKeyPath:@"lastSearchString"];
        }
        @catch (NSException* exception){
            ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
            [Logger logStackTrace:exception];
        }
    }
    [self xvim_dealloc];
}


- (void)xvim_setSelectedRanges:(NSArray *)ranges
                      affinity:(NSSelectionAffinity)affinity
                stillSelecting:(BOOL)flag
{
    [self xvim_setSelectedRanges:ranges affinity:affinity stillSelecting:flag];
    if (self.xvim_view && !XVim.instance.disabled) {
        [self xvim_syncStateFromView];
    }
}

- (void)xvim_selectAll:(id)sender
{
    [self xvim_selectAll:sender];
    if (!XVim.instance.disabled) {
        [self.xvim_view.window syncEvaluatorStack];
    }
}

- (void)xvim_paste:(id)sender
{
    [self xvim_paste:sender];
    if (!XVim.instance.disabled) {
        [self.xvim_view.window syncEvaluatorStack];
    }
}

- (void)xvim_delete:(id)sender
{
    [self xvim_delete:sender];
    if (!XVim.instance.disabled) {
        [self.xvim_view.window syncEvaluatorStack];
    }
}

- (void)xvim_keyDown:(NSEvent *)theEvent
{
    XVimWindow *window = self.xvim_view.window;

    if (!window || XVim.instance.disabled) {
        return [self xvim_keyDown:theEvent];
    }

    @try {
        TRACE_LOG(@"Event:%@, XVimNotation:%@", theEvent.description, XVimKeyNotationFromXVimString([theEvent toXVimString]));
        if ([window handleKeyEvent:theEvent]) {
            [self updateInsertionPointStateAndRestartTimer:YES];
            return;
        }
        // Call Original keyDown:
        [self xvim_keyDown:theEvent];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_mouseDown:(NSEvent *)theEvent
{
    XVimWindow *window = self.xvim_view.window;

    if (!window || XVim.instance.disabled) {
        return [self xvim_mouseDown:theEvent];
    }

    @try {
        TRACE_LOG(@"Event:%@", theEvent.description);


        // When mouse down, NSTextView ( base in this case) takes the control of event loop internally
        // and the method call above does not return immidiately and block until mouse up. mouseDragged: method is called from inside it but
        // it never calls mouseUp: event. After mouseUp event is handled internally it returns the control.
        // So the code here is executed AFTER mouseUp event is handled.
        // At this point NSTextView changes its selectedRange so we usually have to sync XVim state.

        // TODO: To make it simple we should forward mouse events
        //       to handleKeyStroke as a special key stroke
        //       and the key stroke should be handled by the current evaluator.

        [self xvim_mouseDown:theEvent];
        [window syncEvaluatorStack];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_drawRect:(NSRect)dirtyRect
{
    if (XVim.instance.disabled || !self.xvim_view) {
        return [self xvim_drawRect:dirtyRect];
    }

    @try {
        if (XVim.instance.options.hlsearch) {
            XVimMotion *lastSearch = [XVim.instance.searcher motionForRepeatSearch];

            if (nil != lastSearch.regex) {
                [self xvim_updateFoundRanges:lastSearch.regex withOption:lastSearch.option];
            }
        } else {
            [self xvim_clearHighlightText];
        }

        [self xvim_drawRect:dirtyRect];

        if (self.selectionMode != XVIM_VISUAL_NONE) {
            // NSTextView does not draw insertion point when selecting text.
            // We have to draw insertion point by ourselves.
            NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:self.insertionPoint];
            [[[self insertionPointColor] colorWithAlphaComponent:0.5] set];
            NSRectFillUsingOperation(glyphRect, NSCompositeSourceOver);
        }
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

// Drawing Caret
- (void)xvim__drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor
{
    XVimWindow *window = self.xvim_view.window;

    if (!window || XVim.instance.disabled) {
        return [self xvim__drawInsertionPointInRect:aRect color:aColor];
    }

    @try {
        // We do not call original _darawInsertionPointRect here
        // Because it uses NSRectFill to draw the caret which overrides the character entirely.
        // We want some tranceparency for the caret.

        // Call our drawing method
        [window drawInsertionPointInRect:aRect color:aColor];

    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag
{
    [self xvim_drawInsertionPointInRect:rect color:color turnedOn:flag];

    if (!flag && self.xvim_view && !XVim.instance.disabled) {
        // Then tell the view to redraw to clear a caret.
        [self setNeedsDisplay:YES];
    }
}

- (void)xvim_didChangeText
{
    if (self.xvim_view && !XVim.instance.disabled) {
        [self setNeedsUpdateFoundRanges:YES];
    }
    [self xvim_didChangeText];
}

- (void)xvim_viewDidMoveToSuperview
{
    if (!self.xvim_view || XVim.instance.disabled) {
        return [self xvim_viewDidMoveToSuperview];
    }

    @try {
        // Hide scroll bars according to options
        [self xvim_viewDidMoveToSuperview];
        [self.enclosingScrollView setPostsBoundsChangedNotifications:YES];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                             change:(NSDictionary *)change  context:(void *)context
{
	if ([@[ @"ignorecase", @"hlsearch", @"lastSearchString"] containsObject:keyPath]) {
        [self setNeedsUpdateFoundRanges:YES];
        [self setNeedsDisplayInRect:self.visibleRect avoidAdditionalLayout:YES];
    }
}

@end

@implementation XVimView {
    NSTextView *__unsafe_unretained _textView;
}
@synthesize window = _window;
@synthesize textView = _textView;

+ (void)initialize
{
    if (self == [XVimView class]) {
        [NSTextView xvim_initialize];
    }
}

- (instancetype)initWithView:(NSTextView *)view window:(XVimWindow *)window
{
    if ((self = [super init])) {
        DEBUG_LOG("View %p created for %@", self, view);

        _textView = view;
        _window   = [window retain];
        [view xvim_setupForXVimView:self];
        [self _xvim_statusChanged:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_xvim_statusChanged:)
                                                     name:XVimEnabledStatusChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    DEBUG_LOG("View %p deleted", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_window release];
    [super dealloc];
}

- (void)_xvim_statusChanged:(id)sender
{
    if (!XVim.instance.disabled) {
        [_textView xvim_syncStateFromView];
    }
    [_textView setNeedsDisplay:YES];
}

@end
