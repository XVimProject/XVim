//
//  XVimWindow.m
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import <objc/runtime.h>
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimView.h"
#import "XVimUtil.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimOptions.h"
#import "Logger.h"
#import "XVimSearch.h"

#import "IDEEditor+XVim.h"
#import "IDEEditorArea+XVim.h"
#import "DVTSourceTextScrollView+XVim.h"
#import "NSEvent+VimHelper.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimInsertEvaluator.h"

@implementation IDEWorkspaceWindow (XVim)

+ (void)xvim_initialize
{
#if 0 // Only useful for debugging purposes
    if (self == [IDEWorkspaceWindow class]) {
        [self xvim_swizzleInstanceMethod:@selector(sendEvent:)
                                    with:@selector(xvim_sendEvent:)];
    }
#endif
}

- (void)xvim_sendEvent:(NSEvent *)event
{
    if (event.type == NSKeyDown) {
        TRACE_LOG(@"Window:%p keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d",
                  self, event.keyCode, event.characters, event.charactersIgnoringModifiers, event.unmodifiedKeyCode);
    }
    [self xvim_sendEvent:event];
}

@end

@interface XVimWindow () {
    NSMutableArray     *_evaluatorStack;
	XVimKeymapContext  *_keymapContext;
	BOOL                _handlingMouseEvent;
	NSString           *_staticString;
    IDEEditorArea      *_editorArea;
    NSTextInputContext *_inputContext;
}

@property (strong, atomic) NSEvent       *tmpBuffer;
@property (readonly)       XVimEvaluator *currentEvaluator;

- (void)_resetEvaluatorStack:(NSMutableArray *)stack activateNormalHandler:(BOOL)activate;

@end

@implementation XVimWindow
@synthesize commandLine = _commandLine;
@synthesize tmpBuffer = _tmpBuffer;

+ (void)initialize
{
    if (self == [XVimWindow class]) {
        [IDEWorkspaceWindow xvim_initialize];
        [IDEEditorArea xvim_initialize];
        [DVTSourceTextScrollView xvim_initialize];
        [IDEEditor xvim_initialize];
        [IDEComparisonEditor xvim_initialize];
        [XVimView class];
    }
}

- (instancetype)initWithIDEEditorArea:(IDEEditorArea *)editorArea
{
    if (self = [super init]){
        DEBUG_LOG("Window %p created on %@", self, editorArea);
		_staticString = [@"" retain];
		_keymapContext = [[XVimKeymapContext alloc] init];
        _editorArea = [editorArea retain];
        _evaluatorStack = [[NSMutableArray alloc] init];
        _inputContext = [[NSTextInputContext alloc] initWithClient:self];
        [self _resetEvaluatorStack:_evaluatorStack activateNormalHandler:YES];
        _commandLine = [[XVimCommandLine alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bufferChangedNotification:)
                                                     name:XVimBufferChangedNotification object:nil];
	}
    return self;
}

- (NSTextView *)sourceView
{
    IDEEditor *editor = _editorArea.lastActiveEditorContext.editor;

    if ([editor isKindOfClass:[IDEComparisonEditor class]]) {
        editor = [(id)editor keyEditor];
    }

    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return [(id)editor textView];
    }
    return nil;
}

- (XVimView *)currentView
{
    return self.sourceView.xvim_view;
}

- (XVimBuffer *)currentBuffer
{
    return self.currentView.buffer;
}

- (void)dealloc
{
    DEBUG_LOG("Window %p deleted", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_keymapContext release];
    [_staticString release];
    [_editorArea release];
    [_inputContext release];
    self.tmpBuffer = nil;
    [_evaluatorStack release];
    [_commandLine release];
    [super dealloc];
}

- (void)dumpEvaluatorStack:(NSMutableArray*)stack
{
#ifdef DEBUG
    for (NSUInteger i = 0; i < stack.count; i++) {
        XVimEvaluator *e = [stack objectAtIndex:i];

        DEBUG_LOG(@"Evaluator%d:%@   argStr:%@   yankReg:%@", i, NSStringFromClass([e class]), e.argumentString, e.yankRegister);
    }
#endif
}

#pragma mark - Handling keystrokes and evaluation stack

- (XVimEvaluator*)currentEvaluator
{
    return [_evaluatorStack lastObject];
}

- (void)_resetEvaluatorStack:(NSMutableArray *)stack activateNormalHandler:(BOOL)activate
{
    // Initialize evlauator stack
    [stack removeAllObjects];
    XVimEvaluator* firstEvaluator = [[[XVimNormalEvaluator alloc] initWithWindow:self] autorelease];
    [stack addObject:firstEvaluator];
    if (activate) {
        [firstEvaluator becameHandler];
    }
}

- (void)_bufferChangedNotification:(NSNotification *)notification
{
    DEBUG_LOG("Document changed, reset evaluator stack");
    [self.currentEvaluator cancelHandler];
    [_evaluatorStack removeAllObjects];
    [self syncEvaluatorStack];
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
- (BOOL)handleKeyEvent:(NSEvent *)event
{
    if (self.currentEvaluator.mode == XVIM_MODE_INSERT || self.currentEvaluator.mode == XVIM_MODE_CMDLINE) {
        // We must pass the event to the current input method
        // If it is obserbed we do not do anything anymore and handle insertText: or doCommandBySelector:

        // Keep the key input temporary buffer
        self.tmpBuffer = event;

        // The apple document says that we can not call 'activate' method directly
        // but if we do not call this the input is not handled by the input context we own.
        // So we call this every time key input comes.
        [_inputContext activate];

        // Pass it to the input context.
        // This is necesarry for languages like Japanese or Chinese.
        if ([_inputContext handleEvent:event]) {
            return YES;
        }
    }
    return [self handleXVimString:[event toXVimString]];
}

- (BOOL)handleOneXVimString:(XVimString *)oneChar
{
    XVimKeymap *keymap = [self.currentEvaluator selectKeymapWithProvider:[XVim instance]];
    XVimString *mapped = [keymap mapKeys:oneChar withContext:_keymapContext forceFix:NO];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleTimeout) object:nil];
    if (mapped) {
        DEBUG_LOG(@"%@", mapped);

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

    [_commandLine setArgumentString:[self.currentEvaluator argumentDisplayString]];
    [_commandLine setNeedsDisplay:YES];
    return YES;
}

- (BOOL)handleXVimString:(XVimString*)strokes
{
    BOOL last = NO;
    for( XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(strokes) ){
        last = [self handleOneXVimString:[stroke xvimString]];
    }
    return last;
}

- (void)handleTimeout
{
    XVimKeymap *keymap = [self.currentEvaluator selectKeymapWithProvider:[XVim instance]];
    XVimString *mapped = [keymap mapKeys:@"" withContext:_keymapContext forceFix:YES];
    for (XVimKeyStroke *keyStroke in XVimKeyStrokesFromXVimString(mapped)) {
        [self handleKeyStroke:keyStroke onStack:_evaluatorStack];
    }
    [_keymapContext clear];
}

- (void)handleKeyStroke:(XVimKeyStroke *)keyStroke onStack:(NSMutableArray *)evaluatorStack
{
    if( nil == evaluatorStack ){
        // Use default evaluator stack
        evaluatorStack = _evaluatorStack;
    }
    if( evaluatorStack.count == 0 ){
        [self _resetEvaluatorStack:evaluatorStack activateNormalHandler:YES];
    }
    [self dumpEvaluatorStack:evaluatorStack];

    [self clearErrorMessage];

    // Record the event
    XVim *xvim = [XVim instance];
    [xvim appendOperationKeyStroke:[keyStroke xvimString]];

    // Evaluate key stroke
    XVimEvaluator* currentEvaluator = [[evaluatorStack lastObject] retain];
    currentEvaluator.window = self;

    XVimEvaluator* nextEvaluator = [currentEvaluator eval:keyStroke];
    [currentEvaluator release];

    // Manipulate evaluator stack
    while(YES){
        if( nil == nextEvaluator || nextEvaluator == [XVimEvaluator popEvaluator]){
            // current evaluator finished its task
            XVimEvaluator* completeEvaluator = [[[evaluatorStack lastObject] retain] autorelease]; // We have to retain here not to be dealloced in didEndHandler method.
            [evaluatorStack removeLastObject]; // remove current evaluator from the stack
            [completeEvaluator didEndHandler];
            if( [evaluatorStack count] == 0 ){
                // Current Evaluator is the root evaluator of the stack
                [xvim cancelOperationCommands];
                [self _resetEvaluatorStack:evaluatorStack activateNormalHandler:YES];
                break;
            }
            else{
                // Pass current evaluator to the evaluator below the current evaluator
                currentEvaluator = [evaluatorStack lastObject];
                [currentEvaluator becameHandler];
                if (nextEvaluator) {
                    break;
                }
                SEL onCompleteHandler = currentEvaluator.onChildCompleteHandler;
                nextEvaluator = [currentEvaluator performSelector:onCompleteHandler withObject:completeEvaluator];
                [currentEvaluator resetCompletionHandler];
            }
        }else if( nextEvaluator == [XVimEvaluator invalidEvaluator]){
            [xvim cancelOperationCommands];
            [[XVim instance] ringBell];
            [self _resetEvaluatorStack:evaluatorStack activateNormalHandler:YES];
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
    [_commandLine setModeString:[[currentEvaluator modeString] stringByAppendingString:_staticString]];
    [_commandLine setArgumentString:[currentEvaluator argumentDisplayString]];
}

- (void)syncEvaluatorStack
{
    XVimView *xview = self.currentView;
    BOOL needsVisual = (xview.textView.selectedRange.length != 0);

    if (!needsVisual && [self.currentEvaluator isKindOfClass:[XVimInsertEvaluator class]]) {
        return;
    }

    [self.currentEvaluator cancelHandler];
    [self _resetEvaluatorStack:_evaluatorStack activateNormalHandler:!needsVisual];
    [[XVim instance] cancelOperationCommands];

    if (needsVisual) {
        // FIXME:JAS this doesn't work if v is remaped (yeah I know it's silly but...)
        [self handleOneXVimString:@"v"];
    } else {
        [xview adjustCursorPosition];
    }
    [_commandLine setModeString:[self.currentEvaluator.modeString stringByAppendingString:_staticString]];
}

#pragma mark - Visual gimmicks

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color
{
    XVimEvaluator *current = self.currentEvaluator;
	CGFloat heightRatio = [current insertionPointHeightRatio];
    CGFloat widthRatio = [current insertionPointWidthRatio];
    CGFloat alphaRatio = [current insertionPointAlphaRatio];

    [self.currentView drawInsertionPointInRect:rect color:color
                                   heightRatio:heightRatio widthRatio:widthRatio alpha:alphaRatio];
}

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell
{
    [_commandLine errorMessage:message Timer:YES RedColorSetting:YES];
    if (ringBell) {
        [[XVim instance] ringBell];
    }
    return;
}

- (void)statusMessage:(NSString*)message
{
    [_commandLine errorMessage:message Timer:NO RedColorSetting:NO];
}

- (void)clearErrorMessage
{
    [_commandLine errorMessage:@"" Timer:NO RedColorSetting:YES];
}

- (IDEWorkspaceWindow *)currentWorkspaceWindow
{
    return (IDEWorkspaceWindow *)[self.sourceView window];
}

- (void)setForcusBackToSourceView
{
    [[self currentWorkspaceWindow] makeFirstResponder:self.sourceView];
}

#pragma mark - NSTextInputClient Protocol

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange{
    @try {
        self.tmpBuffer = nil;
        [self handleXVimString:aString];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)doCommandBySelector:(SEL)aSelector{
    @try{
        [self handleXVimString:[self.tmpBuffer toXVimString]];
        self.tmpBuffer = nil;
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange{
    return [self.sourceView setMarkedText:aString selectedRange:selectedRange replacementRange:replacementRange];
}

- (void)unmarkText{
    return [self.sourceView unmarkText];
}

- (NSRange)selectedRange{
    return [self.sourceView selectedRange];
}

- (NSRange)markedRange{
    return [self.sourceView markedRange];
}

- (BOOL)hasMarkedText{
    return [self.sourceView hasMarkedText];
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange{
    return [self.sourceView attributedSubstringForProposedRange:aRange actualRange:actualRange];
}

- (NSArray*)validAttributesForMarkedText{
    return [self.sourceView validAttributesForMarkedText];
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange{
    return [self.sourceView firstRectForCharacterRange:aRange actualRange:actualRange];
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint{
    return [self.sourceView characterIndexForPoint:aPoint];
}
@end

