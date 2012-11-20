//
//  XVimBuffer.m
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import "XVimWindow.h"
#import "XVim.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "XVimOptions.h"
#import "Logger.h"
#import <objc/runtime.h>
#import "IDEEditorArea+XVim.h"

@interface XVimWindow() {
	XVimEvaluator* _currentEvaluator;
	XVimKeymapContext* _keymapContext;
	NSMutableDictionary* _localMarks; // key = single letter mark name. value = NSRange (wrapped in a NSValue) for mark location
	BOOL _handlingMouseEvent;
	NSString *_staticString;
}
- (id)initWithIDEEditorArea:(IDEEditorArea*)editorArea;
- (void)setEvaluator:(XVimEvaluator*)evaluator;
- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister fromEvaluator:(XVimEvaluator*)evaluator;
@end

@implementation XVimWindow
@synthesize sourceView = _sourceView;
@synthesize editorArea = _editorArea;
static const char* KEY_WINDOW = "xvimwindow";

+ (XVimWindow*)windowOfIDEEditorArea:(IDEEditorArea *)editorArea {
	return (XVimWindow*)objc_getAssociatedObject(editorArea, KEY_WINDOW);
}

+ (void)createWindowForIDEEditorArea:(IDEEditorArea*)editorArea{
    XVimWindow* w = [[[XVimWindow alloc] initWithIDEEditorArea:editorArea] autorelease];
	objc_setAssociatedObject(editorArea, KEY_WINDOW, w, OBJC_ASSOCIATION_RETAIN);
}

- (id)initWithIDEEditorArea:(IDEEditorArea *)editorArea{
    if (self = [super init]){
		_staticString = @"";
		[self setEvaluator:[[XVimNormalEvaluator alloc] init]];
        _localMarks = [[NSMutableDictionary alloc] init];
		_keymapContext = [[XVimKeymapContext alloc] init];
        self.editorArea = editorArea;
	}
    return self;
}

- (void)dealloc{
    [_keymapContext release];
    [_localMarks release];
    [_staticString release];
    [_currentEvaluator release];
    [_sourceView release];
    self.editorArea = nil;
    [super dealloc];
}

- (XVimCommandLine*)commandLine{
    return [_editorArea commandLine];
}

- (void)willSetEvaluator:(XVimEvaluator*)evaluator {
	if (evaluator != _currentEvaluator && _currentEvaluator){
		[_currentEvaluator willEndHandlerInWindow:self];
	}
}

- (void)setEvaluator:(XVimEvaluator*)evaluator {
	if (!evaluator) {
		evaluator = [[XVimNormalEvaluator alloc] init];
        [[XVim instance] setYankRegisterByName:nil];
	}

	if (evaluator != _currentEvaluator) {
		if (_currentEvaluator) {
			[_currentEvaluator didEndHandlerInWindow:self];
		}

		[_keymapContext clear];

		[self.commandLine setModeString:[[evaluator modeString] stringByAppendingString:_staticString]];
		[self.commandLine setArgumentString:[evaluator argumentDisplayString]];
		[[self sourceView] updateInsertionPointStateAndRestartTimer];

        [_currentEvaluator release];
		_currentEvaluator = evaluator;
		[evaluator becameHandlerInWindow:self];
	}
}

- (XVimEvaluator*)currentEvaluator{
    return _currentEvaluator;
}

- (NSMutableDictionary *)getLocalMarks{
    return _localMarks;
}

- (NSUInteger)insertionPoint {
    return [self.sourceView insertionPoint];
}

- (BOOL)handleKeyEvent:(NSEvent*)event{
    DEBUG_LOG(@"XVimWindow:%p Evaluator:%p Event:%@", self, _currentEvaluator,event.description);
    DEBUG_LOG(@"Before Event Handling  loc:%d   len:%d   ip:%d", self.sourceView.selectedRange.location, self.sourceView.selectedRange.length, [self insertionPoint]);
    
	NSMutableArray *keyStrokeOptions = [[NSMutableArray alloc] init];
	XVimKeyStroke* primaryKeyStroke = [XVimKeyStroke keyStrokeOptionsFromEvent:event into:keyStrokeOptions];
	XVimKeymap* keymap = [_currentEvaluator selectKeymapWithProvider:[XVim instance]];
	
	NSArray *keystrokes = [keymap lookupKeyStrokeFromOptions:keyStrokeOptions 
												 withPrimary:primaryKeyStroke
												 withContext:_keymapContext];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (keystrokes) {
		for (XVimKeyStroke *keyStroke in keystrokes) {
			[self handleKeyStroke:keyStroke];
		}
	} else {
        XVimOptions *options = [[XVim instance] options];
        NSTimeInterval delay = [options.timeoutlen integerValue] / 1000.0;
        if (delay > 0) {
            [self performSelector:@selector(handleTimeout) withObject:nil afterDelay:delay];
        }
    }

	NSString* argString = [_keymapContext toString];
	if ([argString length] == 0) {
		argString = [_currentEvaluator argumentDisplayString];
	}

	[self.commandLine setArgumentString:argString];
    [self.commandLine setNeedsDisplay:YES];
    DEBUG_LOG(@"After Event Handling  loc:%d   len:%d   ip:%d", self.sourceView.selectedRange.location, self.sourceView.selectedRange.length, [self insertionPoint]);
    return YES;
}

- (void)handleTimeout {
    for (XVimKeyStroke *keyStroke in [_keymapContext absorbedKeys]) {
        [self handleKeyStroke:keyStroke];
    }
    [_keymapContext clear];
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke {
    [self clearErrorMessage];
    XVim *xvim = [XVim instance];
	XVimEvaluator* currentEvaluator = _currentEvaluator;
	XVimEvaluator* nextEvaluator = [currentEvaluator eval:keyStroke inWindow:self];

	[self willSetEvaluator:nextEvaluator];

	[self recordEvent:keyStroke intoRegister:xvim.recordingRegister fromEvaluator:currentEvaluator];
	[self recordEvent:keyStroke intoRegister:xvim.repeatRegister fromEvaluator:currentEvaluator];

	[self setEvaluator:nextEvaluator];
}

- (void)handleTextInsertion:(NSString*)text {
	[[self sourceView] insertText:text];
}


- (void)handleVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range; {
	XVimEvaluator *evaluator = [[XVimVisualEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init] mode:mode withRange:range];
	[self willSetEvaluator:evaluator];
	[self setEvaluator:evaluator];
}

- (void)commandFieldLostFocus:(XVimCommandField*)commandField {
	[commandField setDelegate:nil];
	[self willSetEvaluator:nil];
	[self setEvaluator:nil];
}

- (void)recordIntoRegister:(XVimRegister*)xregister{
    XVim *xvim = [XVim instance];
    if (xvim.recordingRegister == nil){
        xvim.recordingRegister = xregister;
        _staticString = @"recording";
        // when you record into a register you clear out any previous recording
        // unless it was capitalized
        [xvim.recordingRegister clear];
    }else{        
        [xvim ringBell];
    }
}

- (void)stopRecordingRegister:(XVimRegister*)xregister{
    XVim *xvim = [XVim instance];
    if (xvim.recordingRegister == nil){
        [xvim ringBell];
    }else{
        xvim.recordingRegister = nil;
		_staticString = @"";
    }
}

- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister fromEvaluator:(XVimEvaluator*)evaluator {
    switch ([evaluator shouldRecordEvent:keyStroke inRegister:xregister]) {
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

- (void)beginMouseEvent:(NSEvent*)event {
    TRACE_LOG(@"Event:%@", event.description);
	_handlingMouseEvent = YES;
}

- (void)endMouseEvent:(NSEvent*)event {
    TRACE_LOG(@"Event:%@", event.description);
	_handlingMouseEvent = NO;
	XVimEvaluator* next = [_currentEvaluator handleMouseEvent:event inWindow:self];
	[self willSetEvaluator:next];
	[self setEvaluator:next];
}

- (void)mouseDown:(NSEvent *)event{
    TRACE_LOG(@"Event:%@", event.description);
    NSPoint point = event.locationInWindow;
    NSPoint pointInView = [[self.sourceView view] convertPoint:point fromView:nil];
    TRACE_LOG(@"Window - x:%f y:%f     View - x:%f y:%f", point.x, point.y, pointInView.x, pointInView.y );
    NSUInteger index = [self.sourceView glyphIndexForPoint:pointInView];
    [self.sourceView endSelection];
    [self.sourceView moveCursor:index];
}

- (void)mouseUp:(NSEvent *)event{
    TRACE_LOG(@"Event:%@", event.description);
    NSPoint point = event.locationInWindow;
    NSPoint pointInView = [[self.sourceView view] convertPoint:point fromView:nil];
    TRACE_LOG(@"Window - x:%f y:%f     View - x:%f y:%f", point.x, point.y, pointInView.x, pointInView.y );
    NSUInteger index = [self.sourceView glyphIndexForPoint:pointInView];
    [self.sourceView moveCursor:index];
}

- (void)mouseDragged:(NSEvent *)event{
    TRACE_LOG(@"Event:%@", event.description);
    NSPoint point = event.locationInWindow;
    NSPoint pointInView = [[self.sourceView view] convertPoint:point fromView:nil];
    TRACE_LOG(@"Window - x:%f y:%f     View - x:%f y:%f", point.x, point.y, pointInView.x, pointInView.y );
    NSUInteger index = [self.sourceView glyphIndexForPoint:pointInView];
    
    if(self.sourceView.selectionMode == MODE_VISUAL_NONE){
        [self.sourceView startSelection:MODE_CHARACTER];
    }
    [self.sourceView moveCursor:index];
}

- (NSRange)restrictSelectedRange:(NSRange)range {
	if (_handlingMouseEvent) {
		range = [_currentEvaluator restrictSelectedRange:range inWindow:self];
	}
	return range;
}

- (void)drawRect:(NSRect)rect {
	[_currentEvaluator drawRect:rect inWindow:self];
}

- (BOOL)shouldDrawInsertionPoint {
	return [_currentEvaluator shouldDrawInsertionPointInWindow:self];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color {
	float heightRatio = [_currentEvaluator insertionPointHeightRatio];
    float widthRatio = [_currentEvaluator insertionPointWidthRatio];
    float alphaRatio = [_currentEvaluator insertionPointAlphaRatio];
    
	XVimSourceView *sourceView = [self sourceView];
	color = [color colorWithAlphaComponent:alphaRatio];
	//NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
	//NSUInteger glyphIndex = [sourceView glyphIndexForPoint:aPoint];
    NSUInteger glyphIndex = [sourceView insertionPoint];
	NSRect glyphRect = [sourceView boundingRectForGlyphIndex:glyphIndex];
	
	[color set];
	rect.size.width =rect.size.height/2;
	if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
		rect.size.width=glyphRect.size.width;
	
	rect.origin.y += (1 - heightRatio) * rect.size.height;
	rect.size.height *= heightRatio;
    rect.size.width *= widthRatio;
	
	NSRectFillUsingOperation( rect, NSCompositeSourceOver);
}

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell {
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine errorMessage:message];
    if (ringBell) {
        [[XVim instance] ringBell];
    }
    return;
}

- (void)clearErrorMessage {
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine errorMessage:@""];
}

- (void)setForcusBackToSourceView{
    [[[self.sourceView view] window] makeFirstResponder:[self.sourceView view]];
}


@end

