//
//  XVimWindow.m
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import "XVimWindow.h"
#import "XVim.h"
#import "XVimUtil.h"
#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimOptions.h"
#import "Logger.h"
#import <objc/runtime.h>
#import "IDEEditorArea+XVim.h"
#import "XVimSearch.h"
#import "NSTextView+VimOperation.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "DVTSourceTextView+XVim.h"
#import "XVimMark.h"
#import "XVimMarks.h"

@interface XVimWindow () {
    NSMutableArray     *_defaultEvaluatorStack;
    NSMutableArray     *_currentEvaluatorStack;
	XVimKeymapContext  *_keymapContext;
	BOOL                _handlingMouseEvent;
	NSString           *_staticString;
    IDEEditorArea      *_editorArea;
    NSTextInputContext *_inputContext;
}

@property (strong, atomic) NSEvent       *tmpBuffer;

- (void)_resetEvaluatorStack:(NSMutableArray *)stack activateNormalHandler:(BOOL)activate;

@end

@implementation XVimWindow
@synthesize commandLine = _commandLine;
@synthesize tmpBuffer = _tmpBuffer;

- (instancetype)initWithIDEEditorArea:(IDEEditorArea *)editorArea
{
    if (self = [super init]){
		_staticString = @"";
		_keymapContext = [[XVimKeymapContext alloc] init];
        _editorArea = editorArea ;
        _defaultEvaluatorStack = [[NSMutableArray alloc] init];
        _currentEvaluatorStack = _defaultEvaluatorStack;
        _inputContext = [[NSTextInputContext alloc] initWithClient:self];
        [self _resetEvaluatorStack:_defaultEvaluatorStack activateNormalHandler:YES];
        _commandLine = [[XVimCommandLine alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentChangedNotification:)
                                                     name:XVimDocumentChangedNotification object:nil];
	}
    return self;
}

- (NSTextView *)sourceView
{
    IDEEditor *editor = _editorArea.lastActiveEditorContext.editor;
    id obj;

    obj = _editorArea.workspaceTabController.windowController.window.firstResponder;
    if ([obj isKindOfClass:[DVTSourceTextView class]]){
        return obj;
    }

    if (_editorArea.editorMode == 2 && [editor isKindOfClass:[IDEComparisonEditor class]]) {
        obj = [[(IDEComparisonEditor *)editor keyEditor] mainScrollView].documentView;
        return obj;
    }

    return editor.mainScrollView.documentView;
}

- (NSTextView *)inputView
{
    if( self.currentEvaluator.mode == XVIM_MODE_CMDLINE ){
        return self.commandLine.commandField;
    }
    return self.sourceView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dumpEvaluatorStack:(NSMutableArray*)stack
{
    for (NSUInteger i = 0; i < stack.count; i++) {
        XVimEvaluator *e = [stack objectAtIndex:i];

        DEBUG_LOG(@"Evaluator%d:%@   argStr:%@   yankReg:%@", i, NSStringFromClass([e class]), e.argumentString, e.yankRegister);
    }
}

#pragma mark - Handling keystrokes and evaluation stack

- (XVimEvaluator*)currentEvaluator
{
    return [_currentEvaluatorStack lastObject];
}

- (void)_resetEvaluatorStack:(NSMutableArray *)stack activateNormalHandler:(BOOL)activate
{
    // Initialize evlauator stack
    [stack removeAllObjects];
    XVimEvaluator* firstEvaluator = [[XVimNormalEvaluator alloc] initWithWindow:self];
    [stack addObject:firstEvaluator];
    if (activate) {
        [firstEvaluator becameHandler];
    }
}

- (void)_documentChangedNotification:(NSNotification *)notification
{
    // Take strong reference to self, because the last remaining strong reference may be
    // in one of the evaluators we are about to dealloc with 'removeAllObjects'
    XVimWindow *this = self;
    [this.currentEvaluator cancelHandler];
    [_currentEvaluatorStack removeAllObjects];
    [this syncEvaluatorStack];
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
    // useinputsourcealways option forces to use input source to input on any mode.
    // This is for French or other keyborads.
    // The reason why we do not want to set this option always on is because
    // under some language (like Japanese) we do not want to let the input source obsorb a key event.
    // Under such language input source waits next input to fix the character to input.
    // Because in normal mode we never send Japanese character to Vim and so thats just nothing but trouble.
    // On the other hand, Franch language uses input source to send character like "}". So they need the help of input source
    // to send command to Vim.
    
    if( [[[[XVim instance] options] getOption:@"alwaysuseinputsource" ] boolValue] ||
        self.currentEvaluator.mode == XVIM_MODE_INSERT ||
        self.currentEvaluator.mode == XVIM_MODE_CMDLINE) {
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
        }else{
            return [self handleXVimString:[event toXVimString]];
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

        [_keymapContext clear];
        for (XVimKeyStroke *keyStroke in XVimKeyStrokesFromXVimString(mapped) ) {
            [self handleKeyStroke:keyStroke onStack:_currentEvaluatorStack];
        }
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
        [self handleKeyStroke:keyStroke onStack:_currentEvaluatorStack];
    }
    [_keymapContext clear];
}

- (void)handleKeyStroke:(XVimKeyStroke *)keyStroke onStack:(NSMutableArray *)evaluatorStack
{
    _currentEvaluatorStack = nil == evaluatorStack ? _defaultEvaluatorStack : evaluatorStack;
    
    if( _currentEvaluatorStack.count == 0 ){
        [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
    }
    [self dumpEvaluatorStack:_currentEvaluatorStack];

    [self clearErrorMessage];

    // Record the event
    XVim *xvim = [XVim instance];
    [xvim appendOperationKeyStroke:[keyStroke xvimString]];

    // Evaluate key stroke
	XVimEvaluator* currentEvaluator = [_currentEvaluatorStack lastObject];
    currentEvaluator.window = self;
	XVimEvaluator* nextEvaluator = [currentEvaluator eval:keyStroke];

    // Manipulate evaluator stack
    while(YES){
        if( nil == nextEvaluator || nextEvaluator == [XVimEvaluator popEvaluator]){
            // current evaluator finished its task
            XVimEvaluator* completeEvaluator = [_currentEvaluatorStack lastObject]; // We have to retain here not to be dealloced in didEndHandler method.
            [_currentEvaluatorStack removeLastObject]; // remove current evaluator from the stack
            [completeEvaluator didEndHandler];
            if( [_currentEvaluatorStack count] == 0 ){
                // Current Evaluator is the root evaluator of the stack
                [xvim cancelOperationCommands];
                [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
                break;
            }
            else{
                // Pass current evaluator to the evaluator below the current evaluator
                currentEvaluator = [_currentEvaluatorStack lastObject];
                [currentEvaluator becameHandler];
                if (nextEvaluator) {
                    break;
                }
                SEL onCompleteHandler = currentEvaluator.onChildCompleteHandler;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                nextEvaluator = [currentEvaluator performSelector:onCompleteHandler withObject:completeEvaluator];
#pragma clang diagnostic pop
                [currentEvaluator resetCompletionHandler];
            }
        }else if( nextEvaluator == [XVimEvaluator invalidEvaluator]){
            [xvim cancelOperationCommands];
            [[XVim instance] ringBell];
            [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
            break;
        }else if( nextEvaluator == [XVimEvaluator noOperationEvaluator] ){
            // Do nothing
            // This is only used by XVimNormalEvaluator AT handler.
            break;
        }else if( currentEvaluator != nextEvaluator ){
            [_currentEvaluatorStack addObject:nextEvaluator];
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

    currentEvaluator = [_currentEvaluatorStack lastObject];
    [_commandLine setModeString:[[currentEvaluator modeString] stringByAppendingString:_staticString]];
    [_commandLine setArgumentString:[currentEvaluator argumentDisplayString]];
    
    _currentEvaluatorStack = _defaultEvaluatorStack;
}

- (void)syncEvaluatorStack
{
    BOOL needsVisual = (self.sourceView.selectedRange.length != 0);

    if (!needsVisual && [self.currentEvaluator isKindOfClass:[XVimInsertEvaluator class]]) {
        return;
    }

    [self.currentEvaluator cancelHandler];
    [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:!needsVisual];
    [[XVim instance] cancelOperationCommands];

    if (needsVisual) {
        // FIXME:JAS this doesn't work if v is remaped (yeah I know it's silly but...)
        [self handleOneXVimString:@"v"];
    } else {
        [self.sourceView xvim_adjustCursorPosition];
    }
    [_commandLine setModeString:[self.currentEvaluator.modeString stringByAppendingString:_staticString]];
}

#pragma mark - Visual gimmicks

- (NSRect)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color
{
    XVimEvaluator *current = self.currentEvaluator;
	float heightRatio = [current insertionPointHeightRatio];
    float widthRatio = [current insertionPointWidthRatio];
    float alphaRatio = [current insertionPointAlphaRatio];

	[[color colorWithAlphaComponent:alphaRatio] set];

	rect.origin.y += (1 - heightRatio) * rect.size.height;
	rect.size.height *= heightRatio;
    rect.size.width *= widthRatio;

	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
    return rect;
}

- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)location{
    if( [self.currentEvaluator isKindOfClass:[XVimInsertEvaluator class]] ){
        DVTSourceTextView *base = (DVTSourceTextView*)self.sourceView;
        return [base xvim_shouldAutoCompleteAtLocation:location];
    }else{
        return NO;
    }
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


- (void)showQuickfixWithString:(NSString *)message completionHandler:(void(^)(void))completionHandler
{
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine quickFixWithString:message completionHandler:completionHandler];
    return;
}

- (void)closeQuickfix
{
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine quickFixWithString:nil completionHandler:nil];
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
    return [self.inputView setMarkedText:aString selectedRange:selectedRange replacementRange:replacementRange];
}

- (void)unmarkText{
    return [self.inputView unmarkText];
}

- (NSRange)selectedRange{
    return [self.inputView selectedRange];
}

- (NSRange)markedRange{
    return [self.inputView markedRange];
}

- (BOOL)hasMarkedText{
    return [self.inputView hasMarkedText];
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange{
    return [self.inputView attributedSubstringForProposedRange:aRange actualRange:actualRange];
}

- (NSArray*)validAttributesForMarkedText{
    return [self.inputView validAttributesForMarkedText];
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange{
    return [self.inputView firstRectForCharacterRange:aRange actualRange:actualRange];
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint{
    return [self.inputView characterIndexForPoint:aPoint];
}

- (XVimMark*)currentPositionMark
{
    XVimMark* mark = [[XVimMark alloc] init];
    NSRange r = [self.sourceView selectedRange];
    mark.document = [[self.sourceView documentURL] path];
    if( nil == mark.document ){
        return nil;
    }
    mark.line = [self.sourceView.textStorage xvim_lineNumberAtIndex:r.location];
    mark.column = [self.sourceView.textStorage xvim_columnOfIndex:r.location];
    return mark;
}

- (void)preMotion:(XVimMotion*)motion
{
    if( ![motion isJumpMotion] ) return;

    XVim* xvim = [XVim instance];
	XVimMark* mark = [self currentPositionMark];
	if( motion.jumpToAnotherFile ){
		// do nothing for jumping to another file
	} else {
		// update single quote mark
		[xvim.marks setMark:mark forName:@"'"];
	}

    [xvim.marks addToJumpListWithMark:mark 
					KeepJumpMarkIndex:motion.keepJumpMarkIndex];
}

@end

