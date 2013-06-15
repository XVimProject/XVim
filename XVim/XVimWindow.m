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
    NSMutableArray* _evaluatorStack;
	XVimKeymapContext* _keymapContext;
	BOOL _handlingMouseEvent;
	NSString *_staticString;
}
- (id)initWithIDEEditorArea:(IDEEditorArea*)editorArea;
- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister fromEvaluator:(XVimEvaluator*)evaluator;
- (void)_initEvaluatorStack;
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
        [self _initEvaluatorStack];
	}
    return self;
}

- (void)dealloc{
    [_keymapContext release];
    [_staticString release];
    [_sourceView release];
    self.editorArea = nil;
    [_evaluatorStack release];
    [super dealloc];
}

- (void)_initEvaluatorStack{
    // Initialize evlauator stack
    [_evaluatorStack removeAllObjects];
    XVimEvaluator* firstEvaluator = [[[XVimNormalEvaluator alloc] initWithWindow:self] autorelease];
    [_evaluatorStack addObject:firstEvaluator];
    [firstEvaluator becameHandler];
}

- (XVimEvaluator*)_currentEvaluator{
    return [_evaluatorStack lastObject];
}

- (XVimCommandLine*)commandLine{
    return [_editorArea commandLine];
}

- (void)willSetEvaluator:(XVimEvaluator*)evaluator {
}

- (NSUInteger)insertionPoint {
    return [self.sourceView insertionPoint];
}

- (BOOL)handleOneXVimString:(XVimString*)oneChar{
    XVimKeymap* keymap = [[self _currentEvaluator] selectKeymapWithProvider:[XVim instance]];
    XVimString* mapped = [keymap mapKeys:oneChar withContext:_keymapContext forceFix:NO];
    DEBUG_LOG(@"%@", mapped);
    
    //NSArray *keystrokes = [keymap lookupKeyStrokeFromOptions:keyStrokeOptions withPrimary:primaryKeyStroke withContext:_keymapContext];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (mapped) {
        for (XVimKeyStroke *keyStroke in [mapped toKeyStrokes]) {
            [self handleKeyStroke:keyStroke];
        }
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
    for( XVimKeyStroke* stroke in [strokes toKeyStrokes] ){
        DEBUG_LOG(@"XVimKeyStroke mod:%x char:%x", stroke.modifier , stroke.character);
        last = [self handleOneXVimString:[stroke xvimString]];
    }
    return last;
}

- (BOOL)handleKeyEvent:(NSEvent*)event{
    DEBUG_LOG(@"XVimWindow:%p Evaluator:%p Event:%@", self, [self _currentEvaluator],event.description);
    //NSMutableArray *keyStrokeOptions = [[[NSMutableArray alloc] init] autorelease];
    //XVimKeyStroke* primaryKeyStroke = [XVimKeyStroke keyStrokeOptionsFromEvent:event into:keyStrokeOptions];
    XVimString* stroke = [XVimKeyStroke eventToXVimString:event];
    DEBUG_LOG(@"XVimString for the Event: %@", stroke );
    return [self handleXVimString:stroke];
}

- (void)handleTimeout {
    XVimKeymap* keymap = [[self _currentEvaluator] selectKeymapWithProvider:[XVim instance]];
    XVimString* mapped = [keymap mapKeys:@"" withContext:_keymapContext forceFix:YES];
    [self handleXVimString:mapped];
    [_keymapContext clear];
}

- (void)dumpEvaluatorStack{
    XVimEvaluator* e;
    for( NSUInteger i = 0 ; i < _evaluatorStack.count ; i ++ ){
        e = [_evaluatorStack objectAtIndex:i];
        DEBUG_LOG(@"Evaluator%d:%@   argStr:%@   yankReg:%@", i, NSStringFromClass([e class]), e.argumentString, e.yankRegister.displayName);
    }
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke {
    [self dumpEvaluatorStack];
    [self syncState];
    
    [self clearErrorMessage];
	XVimEvaluator* currentEvaluator = [_evaluatorStack lastObject];
    currentEvaluator.window = self;
	XVimEvaluator* nextEvaluator = [currentEvaluator eval:keyStroke];
    
    // Record the event
    XVim *xvim = [XVim instance];
	[self recordEvent:keyStroke intoRegister:xvim.recordingRegister fromEvaluator:currentEvaluator];
	[self recordEvent:keyStroke intoRegister:xvim.repeatRegister fromEvaluator:currentEvaluator];
    
    // Manipulate evaluator stack
    while(YES){
        if( nil == nextEvaluator ){
            // current evaluator finished its task
            if( [_evaluatorStack count] == 1 ){
                // Current Evaluator is the root evaluator of the stack
                // And it finished its task. Then we reset the stack.
                [self _initEvaluatorStack];
                break;
            }
            else{
                // Pass current evaluator to the evaluator below the current evaluator
                XVimEvaluator* completeEvaluator = [_evaluatorStack lastObject];
                [_evaluatorStack removeLastObject]; // remove current evaluator from the stack
                [completeEvaluator didEndHandler];
                currentEvaluator = [_evaluatorStack lastObject];
                [currentEvaluator becameHandler];
                 SEL onCompleteHandler = currentEvaluator.onChildCompleteHandler;
                nextEvaluator = [currentEvaluator performSelector:onCompleteHandler withObject:completeEvaluator];
            }
        }else if( nextEvaluator == [XVimEvaluator invalidEvaluator]){
            [[XVim instance] ringBell];
            [self _initEvaluatorStack];
            break;
        }else if( currentEvaluator != nextEvaluator ){
            [_evaluatorStack addObject:nextEvaluator];
            nextEvaluator.parent = currentEvaluator;
            //[currentEvaluator didEndHandler];
            [nextEvaluator becameHandler];
            
            [_keymapContext clear];
            // Not break here. check the nextEvaluator repeatedly.
            break;
        }else{
            // if current and next evaluator is the same do nothing.
            break;
        }
    }
    
    currentEvaluator = [_evaluatorStack lastObject];
    [self.commandLine setModeString:[[currentEvaluator modeString] stringByAppendingString:_staticString]];
    [self.commandLine setArgumentString:[currentEvaluator argumentDisplayString]];
    [self syncState];
}

- (void)handleTextInsertion:(NSString*)text {
	[[self sourceView] insertText:text];
}

- (void)handleVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range; {
	XVimEvaluator *evaluator = [[[XVimVisualEvaluator alloc] initWithWindow:self mode:mode withRange:range] autorelease];
	[self willSetEvaluator:evaluator];
    [_evaluatorStack addObject:evaluator];
}

- (void)commandFieldLostFocus:(XVimCommandField*)commandField {
	[commandField setDelegate:nil];
	[self willSetEvaluator:nil];
    [self _initEvaluatorStack];
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
    [self clearErrorMessage];
	_handlingMouseEvent = NO;
	XVimEvaluator* next = [[self _currentEvaluator] handleMouseEvent:event];
    if( nil != next ){
        [self willSetEvaluator:next];
        [_evaluatorStack addObject:next];
    }else{
        [self _initEvaluatorStack];
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
		range = [[self _currentEvaluator] restrictSelectedRange:range];
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

@end

