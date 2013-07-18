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
#import "XVimSearch.h"

@interface XVimWindow() {
    NSMutableArray* _evaluatorStack;
	XVimKeymapContext* _keymapContext;
	BOOL _handlingMouseEvent;
	NSString *_staticString;
}
@property(strong) IDEEditorArea* editorArea;
@property(strong,nonatomic) NSTextInputContext* inputContext;
@property(strong,nonatomic) XVimMutableString* tmpBuffer;
- (id)initWithIDEEditorArea:(IDEEditorArea*)editorArea;
- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister fromEvaluator:(XVimEvaluator*)evaluator;
- (void)_initEvaluatorStack:(NSMutableArray*)stack;
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
		_staticString = [@"" retain];
		_keymapContext = [[XVimKeymapContext alloc] init];
        self.editorArea = editorArea;
        _evaluatorStack = [[NSMutableArray alloc] init];
        self.inputContext = [[NSTextInputContext alloc] initWithClient:self];
        self.tmpBuffer = [[XVimMutableString alloc] init];
        [self _initEvaluatorStack:_evaluatorStack];
        
	}
    return self;
}

- (void)dealloc{
    [_keymapContext release];
    [_staticString release];
    [_sourceView release];
    self.editorArea = nil;
    self.inputContext = nil;
    self.tmpBuffer = nil;
    [_evaluatorStack release];
    [super dealloc];
}

- (void)_initEvaluatorStack:(NSMutableArray*)stack{
    // Initialize evlauator stack
    [stack removeAllObjects];
    XVimEvaluator* firstEvaluator = [[[XVimNormalEvaluator alloc] initWithWindow:self] autorelease];
    [stack addObject:firstEvaluator];
    [firstEvaluator becameHandler];
}

- (XVimEvaluator*)_currentEvaluator{
    return [_evaluatorStack lastObject];
}

/**
 * handleKeyEvent:
 * This is the entry point of handling one key down event.
 * In Cocoa a key event is handled in following order by default.
 *  - keyDown: method in NSTextView (raw key event. Default impl calls interpertKeyEvents: method)
 *  - interpertKey: method in NSTextView
 *  - handleEvent: method in NSInputTextContext
 *  - (Some processing by Input Method Service such as Japanese or Chinese input system)
 *  - Callback methods(insertText: or doCommandBySelector:) in NSTextView are called from NSInpuTextContext
 *  -
 * See https://developer.apple.com/library/mac/#documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextEditing/TextEditing.html#//apple_ref/doc/uid/TP40009459-CH3-SW2
 *
 *  So the point is that if we intercept keyDwon: method and do not pass it to "interpretKeyEvent" or subsequent methods
 * we can not input Japanese or Chinese correctly.
 *
 *  So what we do here is that 
 *    - Save original key input if it is INSERT or CMDLINE mode
 *    - Call handleEvent in NSInputTextContext with the event
 *      (The NSInputTextContext object is created with this XVimWindow object as its client)
 *    - If insertText: or doCommandBySelector: is called it just passes saved key event(XVimString) to XVimInsertEvaluator or XVimCommandLineEvaluator.
 *    - If they are not called it means that the key input is handled by the input method.
 **/
- (BOOL)handleKeyEvent:(NSEvent*)event{
    if( [self _currentEvaluator].mode == MODE_INSERT || [self _currentEvaluator].mode == MODE_CMDLINE ){
        // We must pass the event to the current input method
        // If it is obserbed we do not do anything anymore and handle insertText: or doCommandBySelector:
        
        // Keep the key input temporary buffer
        [self.tmpBuffer setString:[event toXVimString]];
        
        // The apple document says that we can not call 'activate' method directly
        // but if we do not call this the input is not handled by the input context we own.
        // So we call this every time key input comes.
        [self.inputContext activate];
        
        // Pass it to the input context.
        // This is necesarry for languages like Japanese or Chinese.
        if( [self.inputContext handleEvent:event] ){
            return YES;
        }
    }
    return [self handleXVimString: [event toXVimString]];
}

- (BOOL)handleOneXVimString:(XVimString*)oneChar{
    XVimKeymap* keymap = [[self _currentEvaluator] selectKeymapWithProvider:[XVim instance]];
    XVimString* mapped = [keymap mapKeys:oneChar withContext:_keymapContext forceFix:NO];
    DEBUG_LOG(@"%@", mapped);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (mapped) {
        for (XVimKeyStroke *keyStroke in XVimKeyStrokesFromXVimString(mapped) ) {
            [self handleKeyStroke:keyStroke onStack:_evaluatorStack];
        }
        [_keymapContext clear];
    } else {
        XVimOptions *options = [[XVim instance] options];
        NSTimeInterval delay = [options.timeoutlen integerValue] / 1000.0;
        if (delay > 0) {
            [self performSelector:@selector(handleTimeout) withObject:nil afterDelay:delay];
        }
    }
    
    // FIXME:
    // temporarily toString method is removed.
    // Must be fixed. This makes argument string empty if there are absorbed keys in key mappings.
    NSString* argString = @""; //[_keymapContext toString];
    //if ([argString length] == 0) {
        argString = [[self _currentEvaluator] argumentDisplayString];
    //}
    
    [self.commandLine setArgumentString:argString];
    [self.commandLine setNeedsDisplay:YES];
    
    // For Debugging
    [[self sourceView] dumpState];
    return YES;
}

- (BOOL)handleXVimString:(XVimString*)strokes{
    BOOL last = NO;
    for( XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(strokes) ){
        last = [self handleOneXVimString:[stroke xvimString]];
    }
    return last;
}

- (void)handleTimeout {
    XVimKeymap* keymap = [[self _currentEvaluator] selectKeymapWithProvider:[XVim instance]];
    XVimString* mapped = [keymap mapKeys:@"" withContext:_keymapContext forceFix:YES];
    for (XVimKeyStroke *keyStroke in XVimKeyStrokesFromXVimString(mapped)) {
        [self handleKeyStroke:keyStroke onStack:_evaluatorStack];
    }
    [_keymapContext clear];
}

- (void)dumpEvaluatorStack:(NSMutableArray*)stack{
    XVimEvaluator* e;
    for( NSUInteger i = 0 ; i < stack.count ; i ++ ){
        e = [stack objectAtIndex:i];
        DEBUG_LOG(@"Evaluator%d:%@   argStr:%@   yankReg:%@", i, NSStringFromClass([e class]), e.argumentString, e.yankRegister);
    }
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke onStack:(NSMutableArray*)evaluatorStack{
    
    if( nil == evaluatorStack ){
        // Use default evaluator stack
        evaluatorStack = _evaluatorStack;
    }
    if( evaluatorStack.count == 0 ){
        [self _initEvaluatorStack:evaluatorStack];
    }
    [self dumpEvaluatorStack:evaluatorStack];
    [self syncState];
    
    [self clearErrorMessage];
    
    // Record the event
    XVim *xvim = [XVim instance];
    [xvim appendRepeatKeyStroke:[keyStroke xvimString]];
    
    // Evaluate key stroke
	XVimEvaluator* currentEvaluator = [evaluatorStack lastObject];
    currentEvaluator.window = self;
	XVimEvaluator* nextEvaluator = [currentEvaluator eval:keyStroke];
    
    // Manipulate evaluator stack
    while(YES){
        if( nil == nextEvaluator ){
            // current evaluator finished its task
            XVimEvaluator* completeEvaluator = [evaluatorStack lastObject];
            [evaluatorStack removeLastObject]; // remove current evaluator from the stack
            [completeEvaluator didEndHandler];
            if( [evaluatorStack count] == 0 ){
                // Current Evaluator is the root evaluator of the stack
                [xvim cancelRepeatCommand];
                [self _initEvaluatorStack:evaluatorStack];
                break;
            }
            else{
                // Pass current evaluator to the evaluator below the current evaluator
                currentEvaluator = [evaluatorStack lastObject];
                [currentEvaluator becameHandler];
                 SEL onCompleteHandler = currentEvaluator.onChildCompleteHandler;
                nextEvaluator = [currentEvaluator performSelector:onCompleteHandler withObject:completeEvaluator];
            }
        }else if( nextEvaluator == [XVimEvaluator invalidEvaluator]){
            [xvim cancelRepeatCommand];
            [[XVim instance] ringBell];
            [self _initEvaluatorStack:evaluatorStack];
            break;
        }else if( nextEvaluator == [XVimEvaluator noOperationEvaluator] ){
            // Do nothing
            // This is only used by XVimNormalEvaluator AT handler.
            break;
        }else if( currentEvaluator != nextEvaluator ){
            [evaluatorStack addObject:nextEvaluator];
            nextEvaluator.parent = currentEvaluator;
            //[currentEvaluator didEndHandler];
            [nextEvaluator becameHandler];
            // Not break here. check the nextEvaluator repeatedly.
            break;
        }else{
            // if current and next evaluator is the same do nothing.
            break;
        }
    }
    
    currentEvaluator = [evaluatorStack lastObject];
    [self.commandLine setModeString:[[currentEvaluator modeString] stringByAppendingString:_staticString]];
    [self.commandLine setArgumentString:[currentEvaluator argumentDisplayString]];
    [self syncState];
}

- (void)handleTextInsertion:(NSString*)text {
	[[self sourceView] insertText:text];
}

- (void)handleVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range; {
	XVimEvaluator *evaluator = [[[XVimVisualEvaluator alloc] initWithWindow:self mode:mode withRange:range] autorelease];
    [_evaluatorStack addObject:evaluator];
}

- (void)commandFieldLostFocus:(XVimCommandField*)commandField {
	[commandField setDelegate:nil];
    [self _initEvaluatorStack:_evaluatorStack];
}

- (void)recordIntoRegister:(XVimRegister*)xregister{
/*
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
 */
}

- (void)stopRecordingRegister:(XVimRegister*)xregister{
/*
 XVim *xvim = [XVim instance];
    if (xvim.recordingRegister == nil){
        [xvim ringBell];
    }else{
        xvim.recordingRegister = nil;
		_staticString = @"";
    }
 */
}

- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister fromEvaluator:(XVimEvaluator*)evaluator {
    /*
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
     */
}

- (void)beginMouseEvent:(NSEvent*)event {
    TRACE_LOG(@"Event:%@", event.description);
	_handlingMouseEvent = YES;
}

- (void)endMouseEvent:(NSEvent*)event {
    TRACE_LOG(@"Event:%@", event.description);
    [self clearErrorMessage];
	_handlingMouseEvent = NO;
	XVimEvaluator* next = [[self _currentEvaluator] handleMouseEvent:event];
    if( nil != next ){
        [_evaluatorStack addObject:next];
    }else{
        [self _initEvaluatorStack:_evaluatorStack];
    }
}

- (void)mouseDown:(NSEvent *)event{
    TRACE_LOG(@"Event:%@", event.description);
    NSPoint point = event.locationInWindow;
    NSPoint pointInView = [[self.sourceView view] convertPoint:point fromView:nil];
    NSUInteger index = [self.sourceView glyphIndexForPoint:pointInView];
    [[self sourceView] changeSelectionMode:MODE_VISUAL_NONE];
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = index;
    [[self sourceView] move:m];
}

- (void)mouseUp:(NSEvent *)event{
    TRACE_LOG(@"Event:%@", event.description);
    /*1
    NSPoint point = event.locationInWindow;
    NSPoint pointInView = [[self.sourceView view] convertPoint:point fromView:nil];
    NSUInteger index = [self.sourceView glyphIndexForPoint:pointInView];
     */
    [self endMouseEvent:event];
}

- (void)mouseDragged:(NSEvent *)event{
    TRACE_LOG(@"Event:%@", event.description);
    NSPoint point = event.locationInWindow;
    NSPoint pointInView = [[self.sourceView view] convertPoint:point fromView:nil];
    NSUInteger index = [self.sourceView glyphIndexForPoint:pointInView];
    
    if(self.sourceView.selectionMode == MODE_VISUAL_NONE){
        [self.sourceView changeSelectionMode:MODE_CHARACTER];
    }
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = index;
    [[self sourceView] move:m];
    [self endMouseEvent:event];
     
}

- (NSRange)restrictSelectedRange:(NSRange)range {
	if (_handlingMouseEvent) {
		//range = [[self _currentEvaluator] restrictSelectedRange:range];
	}
	return range;
}

- (void)drawRect:(NSRect)rect {
	[[self _currentEvaluator] drawRect:rect];
}

- (BOOL)shouldDrawInsertionPoint {
	return [[self _currentEvaluator] shouldDrawInsertionPoint];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color {
	float heightRatio = [[self _currentEvaluator] insertionPointHeightRatio];
    float widthRatio = [[self _currentEvaluator] insertionPointWidthRatio];
    float alphaRatio = [[self _currentEvaluator] insertionPointAlphaRatio];
    
	XVimSourceView *sourceView = [self sourceView];
	color = [color colorWithAlphaComponent:alphaRatio];
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
    [commandLine errorMessage:message Timer:YES RedColorSetting:YES];
    if (ringBell) {
        [[XVim instance] ringBell];
    }
    return;
}

- (void)statusMessage:(NSString*)message {
    XVimCommandLine *commandLine = self.commandLine;
    [commandLine errorMessage:message Timer:NO RedColorSetting:NO];
}

- (void)clearErrorMessage {
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine errorMessage:@"" Timer:NO RedColorSetting:YES];
}

- (void)setForcusBackToSourceView{
    [[[self.sourceView view] window] makeFirstResponder:[self.sourceView view]];
}

- (IDEWorkspaceWindow*)currentWorkspaceWindow{
    IDEWorkspaceWindow* window = (IDEWorkspaceWindow*)[[self.sourceView view] window];
    return window;
}

- (XVimCommandLine*)commandLine{
    return [_editorArea commandLine];
}

- (NSUInteger)insertionPoint {
    return [self.sourceView insertionPoint];
}

- (void)syncState{
    [self.sourceView syncStateFromView];
}

static char s_associate_key = 0;

+ (XVimWindow*)associateOf:(id)object {
	return (XVimWindow*)objc_getAssociatedObject(object, &s_associate_key);
}

- (void)associateWith:(id)object {
	objc_setAssociatedObject(object, &s_associate_key, self, OBJC_ASSOCIATION_RETAIN);
}


// NSTextInputClient Protocol
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange{
    [self.tmpBuffer setString:@""];
    [self handleXVimString:aString];
    //return [[self.sourceView view] insertText:aString replacementRange:replacementRange];
}

- (void)doCommandBySelector:(SEL)aSelector{
    TRACE_LOG(@"Selector:%@", NSStringFromSelector(aSelector));
    [self handleXVimString:self.tmpBuffer];
    [self.tmpBuffer setString:@""];
    /*
    NSString* selector = NSStringFromSelector(aSelector);
    if( [selector isEqualToString:@"cancelOperation:"] ){
        [self handleXVimString:XVimStringFromKeyNotation(@"<ESC>")];
    }
     */
    //return [[self.sourceView view] doCommandBySelector:aSelector];
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange{
    return [[self.sourceView view] setMarkedText:aString selectedRange:selectedRange replacementRange:replacementRange];
}

- (void)unmarkText{
    return [[self.sourceView view] unmarkText];
}

- (NSRange)selectedRange{
    return [[self.sourceView view] selectedRange];
}

- (NSRange)markedRange{
    return [[self.sourceView view] markedRange];
}

- (BOOL)hasMarkedText{
    return [[self.sourceView view] hasMarkedText];
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange{
    return [[self.sourceView view] attributedSubstringForProposedRange:aRange actualRange:actualRange];
}

- (NSArray*)validAttributesForMarkedText{
    return [[self.sourceView view] validAttributesForMarkedText];
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange{
    return [[self.sourceView view] firstRectForCharacterRange:aRange actualRange:actualRange];
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint{
    return [[self.sourceView view] characterIndexForPoint:aPoint];
}
@end

