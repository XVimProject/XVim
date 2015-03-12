//
//  XVimInsertEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimInsertEvaluator.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimKeyStroke.h"
#import "XVimKeymapProvider.h"
#import "XVimVisualEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimNormalEvaluator.h"
#import "NSTextView+VimOperation.h"
#import "DVTKit.h"

@interface XVimInsertEvaluator()
@property (nonatomic) NSRange startRange;
@property (nonatomic) BOOL movementKeyPressed;
@property (nonatomic, strong) NSString *lastInsertedText;
@property (nonatomic, readonly, strong) NSArray *cancelKeys;
@property (nonatomic, readonly, strong) NSArray *movementKeys;
@property (nonatomic) BOOL enoughBufferForReplace;
@end

@implementation XVimInsertEvaluator{
    BOOL _insertedEventsAbort;
    NSMutableArray* _insertedEvents;
    NSUInteger _blockEditColumn;
    XVimRange _blockLines;
    XVimInsertionPoint _mode;
}

@synthesize startRange = _startRange;
@synthesize cancelKeys = _cancelKeys;
@synthesize movementKeys = _movementKeys;
@synthesize lastInsertedText = _lastInsertedText;
@synthesize movementKeyPressed = _movementKeyPressed;
@synthesize enoughBufferForReplace = _enoughBufferForReplace;


- (id)initWithWindow:(XVimWindow *)window{
    return [self initWithWindow:window mode:XVIM_INSERT_DEFAULT];
}

- (id)initWithWindow:(XVimWindow*)window mode:(XVimInsertionPoint)mode{
    self = [super initWithWindow:window];
    if (self) {
        _mode = mode;
        _blockEditColumn = NSNotFound;
        _blockLines = XVimMakeRange(NSNotFound, NSNotFound);
        _lastInsertedText = @"";
        _movementKeyPressed = NO;
        _insertedEventsAbort = NO;
        _enoughBufferForReplace = YES;
        _cancelKeys = [[NSArray alloc] initWithObjects:
                       [NSValue valueWithPointer:@selector(ESC:)],
                       [NSValue valueWithPointer:@selector(C_LSQUAREBRACKET:)],
                       [NSValue valueWithPointer:@selector(C_c:)],
                       nil];
        _movementKeys = [[NSArray alloc] initWithObjects:
                         [NSValue valueWithPointer:@selector(Up:)],
                         [NSValue valueWithPointer:@selector(Down:)],
                         [NSValue valueWithPointer:@selector(Left:)],
                         [NSValue valueWithPointer:@selector(Right:)],
                         nil];
    }
    return self;
}


- (NSString*)modeString{
	return @"-- INSERT --";
}
- (XVIM_MODE)mode{
    return XVIM_MODE_INSERT;
}

- (void)becameHandler{
    [super becameHandler];
    [self.sourceView xvim_insert:_mode blockColumn:&_blockEditColumn blockLines:&_blockLines];
    self.startRange = [[self sourceView] selectedRange];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
	return [keymapProvider keymapForMode:XVIM_MODE_INSERT];
}

- (NSString*)insertedText{
    NSTextView* view = [self sourceView];
    NSUInteger startLoc = self.startRange.location;
    NSUInteger endLoc = [view selectedRange].location;
    NSRange textRange = NSMakeRange(NSNotFound, 0);

    if( [[view string] length] == 0 ){
        return @"";
    }
    // If some text are deleted while editing startLoc could be out of range of the view's string.
    if( ( startLoc >= [[view string] length] ) ){
        startLoc = [[view string] length] - 1;
    }

    // Is this really what we want to do?
    // This means just moving cursor forward or backward and escape from insert mode generates the inserted test this method return.
    //    -> The answer is 'OK'. see onMovementKeyPressed: method how it treats the inserted text.
    if (endLoc > startLoc ){
        textRange = NSMakeRange(startLoc, endLoc - startLoc);
    }else{
        textRange = NSMakeRange(endLoc , startLoc - endLoc);
    }
    NSString *text = [[view string] substringWithRange:textRange];
    return text;

}

/*
- (void)recordTextIntoRegister:(XVimRegister*)xregister{
    NSString *text = [self insertedText];
    if (text.length > 0){
        [xregister appendText:text];
    }
}
 */

- (void)onMovementKeyPressed{
    // TODO: we also have to handle when cursor is movieng by mouse clicking.
    //       it should have the same effect on movementKeyPressed property.
    _insertedEventsAbort = YES;
    if (!self.movementKeyPressed){
        self.movementKeyPressed = YES;

        // Store off any needed text
        self.lastInsertedText = [self insertedText];
        //[self recordTextIntoRegister:[XVim instance].recordingRegister];
    }

    // Store off the new start range
    self.startRange = [[self sourceView] selectedRange];
}

- (void)repeatBlockText {
    NSString *text = [self insertedText];
    for( NSUInteger i = 0 ; i < [self numericArg]-1; i++ ){
        [self.sourceView insertText:text];
    }

    if (_blockEditColumn != NSNotFound) {
        XVimRange range = XVimMakeRange(_blockLines.begin + 1, _blockLines.end);
        [self.sourceView xvim_blockInsertFixupWithText:text mode:_mode count:self.numericArg
                                                column:_blockEditColumn lines:range];
    }
}

- (void)didEndHandler{
    [super didEndHandler];
	NSTextView *sourceView = [self sourceView];

    if( !_insertedEventsAbort ){
        [self repeatBlockText];
    }

    // Store off any needed text
    XVim *xvim = [XVim instance];
    xvim.lastVisualMode = self.sourceView.selectionMode;
    [xvim fixOperationCommands];
    if (!self.movementKeyPressed){
        //[self recordTextIntoRegister:xvim.recordingRegister];
        //[self recordTextIntoRegister:xvim.repeatRegister];
    }else if(self.lastInsertedText.length > 0){
        //[xvim.repeatRegister appendText:self.lastInsertedText];
    }
    [sourceView xvim_hideCompletions];

    // Position for "^" is before escaped from insert mode
    NSUInteger pos = self.sourceView.insertionPoint;
    XVimMark* mark = XVimMakeMark([self.sourceView.textStorage xvim_lineNumberAtIndex:pos], [self.sourceView.textStorage xvim_columnOfIndex:pos], self.sourceView.documentURL.path);
    if( nil != mark.document ){
        [[XVim instance].marks setMark:mark forName:@"^"];
    }

    [[self sourceView] xvim_escapeFromInsert];

    // Position for "." is after escaped from insert mode
    pos = self.sourceView.insertionPoint;
    mark = XVimMakeMark([self.sourceView.textStorage xvim_lineNumberAtIndex:pos], [self.sourceView.textStorage xvim_columnOfIndex:pos], self.sourceView.documentURL.path);
    if( nil != mark.document ){
        [[XVim instance].marks setMark:mark forName:@"."];
    }

}

- (BOOL)windowShouldReceive:(SEL)keySelector {
  BOOL b = YES ^ ([NSStringFromSelector(keySelector) isEqualToString:@"C_e:"] ||
                  [NSStringFromSelector(keySelector) isEqualToString:@"C_y:"]);
  return b;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    XVimEvaluator *nextEvaluator = self;

    SEL keySelector = keyStroke.selector;
    if ([self respondsToSelector:keySelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        nextEvaluator = [self performSelector:keySelector];
#pragma clang diagnostic pop
    } else {
        if (self.movementKeyPressed) {
            // Flag movement key as not pressed until the next movement key is pressed
            self.movementKeyPressed = NO;

            // Store off the new start range
            self.startRange = self.sourceView.selectedRange;
        }
        keySelector = nil;
    }

    if (nextEvaluator == self && nil == keySelector){
        NSEvent *event = [keyStroke toEventwithWindowNumber:0 context:nil];
        if ([self windowShouldReceive:keySelector]) {
            // Here we pass the key input to original text view.
            // The input coming to this method is already handled by "Input Method"
            // and the input maight be non ascii like 'あ'
            if (keyStroke.isPrintable) {
                [self.sourceView insertText:keyStroke.xvimString];
            }else{
                [self.sourceView interpretKeyEvents:[NSArray arrayWithObject:event]];
            }
        }
    }
    return nextEvaluator;
}

- (XVimEvaluator*)C_c{
    return [self ESC];
}

- (XVimEvaluator*)C_e{
    [self C_yC_eHelper:NO];
    return self;
}

// Experimental
- (XVimEvaluator*)C_n{
    DVTSourceTextView* view = (DVTSourceTextView*)self.window.sourceView;
    DVTTextCompletionController* c = [view completionController];
    DVTTextCompletionSession *currentSession = c.currentSession;
    if( nil == currentSession){
        [view complete:self];
    }else{
        [currentSession selectNextCompletionAlpha];
    }
    return self;
}

- (XVimEvaluator*)C_p{
    DVTSourceTextView* view = (DVTSourceTextView*)self.window.sourceView;
    DVTTextCompletionController* c = [view completionController];
    DVTTextCompletionSession *currentSession = c.currentSession;
    if( nil == currentSession){
        [view complete:self];
    }else{
        [currentSession selectPreviousCompletionAlpha];
    }
    return self;
}

- (XVimEvaluator*)C_o{
    self.onChildCompleteHandler = @selector(onC_oComplete:);
    return [[XVimNormalEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)onC_oComplete:(XVimEvaluator*)childEvaluator{
    self.onChildCompleteHandler = nil;
    return self;
}

- (XVimEvaluator*)C_w{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    [[self sourceView] xvim_delete:m andYank:NO];
    return self;
}

- (XVimEvaluator*)C_y{
    [self C_yC_eHelper:YES];
    return self;
}

- (XVimEvaluator*)ESC{
    return nil;
}

- (XVimEvaluator*)C_LSQUAREBRACKET{
    return [self ESC];
}

- (void)C_yC_eHelper:(BOOL)handlingC_y {
    NSUInteger currentCursorIndex = [self.sourceView selectedRange].location;
    NSUInteger currentColumnIndex = [self.sourceView.textStorage xvim_columnOfIndex:currentCursorIndex];
    NSUInteger newCharIndex;
    if (handlingC_y) {
        newCharIndex = [self.sourceView.textStorage prevLine:currentCursorIndex column:currentColumnIndex count:[self numericArg] option:MOTION_OPTION_NONE];
    } else {
        newCharIndex = [self.sourceView.textStorage nextLine:currentCursorIndex column:currentColumnIndex count:[self numericArg] option:MOTION_OPTION_NONE];
    }
    NSUInteger newColumnIndex = [self.sourceView.textStorage xvim_columnOfIndex:newCharIndex];
    NSLog(@"Old column: %ld\tNew column: %ld", currentColumnIndex, newColumnIndex);
    if (currentColumnIndex == newColumnIndex) {
        unichar u = [[[self sourceView] string] characterAtIndex:newCharIndex];
        NSString *charToInsert = [NSString stringWithFormat:@"%c", u];
        [[self sourceView] insertText:charToInsert];
    }
}

@end