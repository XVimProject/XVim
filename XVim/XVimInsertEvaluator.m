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
#import "XVimView.h"
#import "NSTextStorage+VimOperation.h"

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
    BOOL _oneCharMode;
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
    return [self initWithWindow:window oneCharMode:NO mode:XVIM_INSERT_DEFAULT];
}

- (id)initWithWindow:(XVimWindow*)window oneCharMode:(BOOL)oneCharMode mode:(XVimInsertionPoint)mode{
    self = [super initWithWindow:window];
    if (self) {
        _mode = mode;
        _blockEditColumn = NSNotFound;
        _blockLines = XVimMakeRange(NSNotFound, NSNotFound);
        _lastInsertedText = [@"" retain];
        _oneCharMode = oneCharMode;
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

- (void)dealloc
{
    [_lastInsertedText release];
    [_cancelKeys release];
    [_movementKeys release];
    [super dealloc];
}

- (NSString*)modeString{
	return @"-- INSERT --";
}
- (XVIM_MODE)mode{
    return XVIM_MODE_INSERT;
}

- (void)becameHandler{
    [super becameHandler];
    [self.currentView doInsert:_mode blockColumn:&_blockEditColumn blockLines:&_blockLines];
    self.startRange = self.currentView.textView.selectedRange;
}

- (CGFloat)insertionPointHeightRatio{
    if(_oneCharMode){
        return 0.25;
    }
    return 1.0;
}

- (CGFloat)insertionPointWidthRatio{
    if(_oneCharMode){
        return 1.0;
    }
    return 0.15;
}

- (CGFloat)insertionPointAlphaRatio{
    if(_oneCharMode){
        return 0.5;
    }
    return 1.0;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
	return [keymapProvider keymapForMode:XVIM_MODE_INSERT];
}

- (NSString*)insertedText{
    XVimView   *xview  = self.currentView;
    XVimBuffer *buffer = self.window.currentBuffer;
    NSUInteger startLoc = self.startRange.location;
    NSUInteger endLoc = xview.textView.selectedRange.location;
    NSRange textRange = NSMakeRange(NSNotFound, 0);
    
    if (buffer.length == 0 ){
        return @"";
    }
    // If some text are deleted while editing startLoc could be out of range of the view's string.
    if (startLoc >= buffer.length) {
        startLoc = buffer.length - 1;
    }
    
    // Is this really what we want to do?
    // This means just moving cursor forward or backward and escape from insert mode generates the inserted test this method return.
    //    -> The answer is 'OK'. see onMovementKeyPressed: method how it treats the inserted text.
    if (endLoc > startLoc) {
        textRange = NSMakeRange(startLoc, endLoc - startLoc);
    }else{
        textRange = NSMakeRange(endLoc , startLoc - endLoc);
    }
    
    return [buffer.string substringWithRange:textRange];
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
    self.startRange = self.currentView.textView.selectedRange;
}

- (void)didEndHandler{
    [super didEndHandler];

    XVimView   *xview = self.currentView;
	NSTextView *sourceView = xview.textView;
    XVimBuffer *buffer = self.window.currentBuffer;

    if( !_insertedEventsAbort && !_oneCharMode ){
        NSString *text = [self insertedText];
        for( int i = 0 ; i < [self numericArg]-1; i++ ){
            [sourceView insertText:text];
        }

        if (_blockEditColumn != NSNotFound) {
            XVimRange range = XVimMakeRange(_blockLines.begin + 1, _blockLines.end);
            [xview doInsertFixupWithText:text mode:_mode count:self.numericArg
                                  column:_blockEditColumn lines:range];
        }
    }

    // Store off any needed text
    XVim *xvim = [XVim instance];
    [xvim fixOperationCommands];
    if (_oneCharMode) {
    } else if (!self.movementKeyPressed) {
        //[self recordTextIntoRegister:xvim.recordingRegister];
        //[self recordTextIntoRegister:xvim.repeatRegister];
    } else if (self.lastInsertedText.length > 0) {
        //[xvim.repeatRegister appendText:self.lastInsertedText];
    }
    [xview xvim_hideCompletions];

    // Position for "^" is before escaped from insert mode
    XVimPosition pos = xview.insertionPosition;
    XVimMark *mark = XVimMakeMark(pos.line, pos.column, buffer.document);
    if (nil != mark.document) {
        [[XVim instance].marks setMark:mark forName:@"^"];
    }

    [xview escapeFromInsertAndMoveBack:YES];

    // Position for "." is after escaped from insert mode
    pos = xview.insertionPosition;
    mark = XVimMakeMark(pos.line, pos.column, buffer.document);
    if (nil != mark.document) {
        [[XVim instance].marks setMark:mark forName:@"."];
    }
}

- (BOOL)windowShouldReceive:(SEL)keySelector {
  BOOL b = YES ^ ([NSStringFromSelector(keySelector) isEqualToString:@"C_e:"] ||
                  [NSStringFromSelector(keySelector) isEqualToString:@"C_y:"]);
  return b;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    XVimView   *xview = self.currentView;
    XVimEvaluator *nextEvaluator = self;

    SEL keySelector = [keyStroke selectorForInstance:self];
    if (keySelector){
        nextEvaluator = [self performSelector:keySelector];
    }else if(self.movementKeyPressed){
        // Flag movement key as not pressed until the next movement key is pressed
        self.movementKeyPressed = NO;
        
        // Store off the new start range
        self.startRange = self.currentView.textView.selectedRange;
    }
    
    if (nextEvaluator == self && nil == keySelector){
        NSEvent *event = [keyStroke toEventwithWindowNumber:0 context:nil];
        if (_oneCharMode) {
            if (!keyStroke.isPrintable) {
                [xview escapeFromInsertAndMoveBack:NO];
                nextEvaluator = [XVimEvaluator invalidEvaluator];
            } else if (![xview doReplaceCharacters:keyStroke.character count:[self numericArg]]) {
                [xview escapeFromInsertAndMoveBack:NO];
                nextEvaluator = [XVimEvaluator invalidEvaluator];
            }else{
                nextEvaluator = nil;
            }
        } else if ([self windowShouldReceive:keySelector]) {
            // Here we pass the key input to original text view.
            // The input coming to this method is already handled by "Input Method"
            // and the input maight be non ascii like 'あ'
            if (keyStroke.isPrintable){
                [xview.textView insertText:keyStroke.xvimString];
            }else{
                [xview.textView interpretKeyEvents:[NSArray arrayWithObject:event]];
            }
        }
    }
    return nextEvaluator;
}

- (XVimEvaluator*)C_o{
    self.onChildCompleteHandler = @selector(onC_oComplete:);
    return [[[XVimNormalEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onC_oComplete:(XVimEvaluator*)childEvaluator{
    self.onChildCompleteHandler = nil;
    return self;
}

- (XVimEvaluator*)ESC{
    return nil;
}

- (XVimEvaluator*)C_LSQUAREBRACKET{
    return [self ESC];
}

- (XVimEvaluator*)C_c{
    return [self ESC];
}

- (void)C_yC_eHelper:(BOOL)handlingC_y
{
    XVimBuffer *buffer = self.window.currentBuffer;
    XVimView   *xview  = self.currentView;

    XVimPosition pos = xview.insertionPosition;
    NSUInteger indexToCopy;

    if (handlingC_y) {
        indexToCopy = [buffer indexOfLineNumber:pos.line - 1 column:pos.column];
    } else {
        indexToCopy = [buffer indexOfLineNumber:pos.line + 1 column:pos.column];
    }
    if (indexToCopy == NSNotFound || [buffer isIndexAtEndOfLine:indexToCopy]) {
        return;
    }

    unichar c = [buffer.string characterAtIndex:indexToCopy];
    NSString *s = [[NSString alloc] initWithCharacters:&c length:1];

    NSUInteger index = xview.insertionPoint;
    [buffer beginEditingAtIndex:index];
    [buffer replaceCharactersInRange:NSMakeRange(index, 0) withString:s];
    [buffer endEditingAtIndex:index + 1];
    [xview moveCursorToIndex:index + 1];
}

- (XVimEvaluator*)C_y{
    [self C_yC_eHelper:YES];
    return self;
}

- (XVimEvaluator*)C_e{
    [self C_yC_eHelper:NO];
    return self;
}

- (XVimEvaluator*)C_w{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1);
    [self.currentView doDelete:m andYank:NO];
    return self;
}

@end
