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
}

@synthesize startRange = _startRange;
@synthesize cancelKeys = _cancelKeys;
@synthesize movementKeys = _movementKeys;
@synthesize lastInsertedText = _lastInsertedText;
@synthesize movementKeyPressed = _movementKeyPressed;
@synthesize enoughBufferForReplace = _enoughBufferForReplace;


- (id)initWithWindow:(XVimWindow *)window{
    return [self initWithWindow:window oneCharMode:NO];
}

- (id)initWithWindow:(XVimWindow*)window oneCharMode:(BOOL)oneCharMode{
    self = [super initWithWindow:window];
    if (self) {
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
    self.startRange = [[self sourceView] selectedRange];
    [self.sourceView xvim_insert];
}

- (float)insertionPointHeightRatio{
    if(_oneCharMode){
        return 0.25;
    }
    return 1.0;
}

- (float)insertionPointWidthRatio{
    if(_oneCharMode){
        return 1.0;
    }
    return 0.15;
}

- (float)insertionPointAlphaRatio{
    if(_oneCharMode){
        return 0.5;
    }
    return 1.0;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
	return [keymapProvider keymapForMode:XVIM_MODE_INSERT];
}

- (NSString*)getInsertedText{
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
    NSString *text = [self getInsertedText];
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
        self.lastInsertedText = [self getInsertedText];
        //[self recordTextIntoRegister:[XVim instance].recordingRegister];
    }
    
    // Store off the new start range
    self.startRange = [[self sourceView] selectedRange];
}

- (void)didEndHandler{
    [super didEndHandler];
	NSTextView *sourceView = [self sourceView];
	
    if( !_insertedEventsAbort && !_oneCharMode ){
        NSString *text = [self getInsertedText];
        for( int i = 0 ; i < [self numericArg]-1; i++ ){
            [sourceView insertText:text];
        }
    }
    
    // Store off any needed text
    XVim *xvim = [XVim instance];
    xvim.lastVisualMode = self.sourceView.selectionMode;
    [xvim fixOperationCommands];
    if( _oneCharMode ){
    }else if (!self.movementKeyPressed){
        //[self recordTextIntoRegister:xvim.recordingRegister];
        //[self recordTextIntoRegister:xvim.repeatRegister];
    }else if(self.lastInsertedText.length > 0){
        //[xvim.repeatRegister appendText:self.lastInsertedText];
    }
    [sourceView xvim_hideCompletions];
	
    // Position for "^" is before escaped from insert mode
    NSUInteger pos = self.sourceView.insertionPoint;
    XVimMark* mark = XVimMakeMark([self.sourceView.textStorage lineNumber:pos], [self.sourceView.textStorage columnNumber:pos], self.sourceView.documentURL.path);
    if( nil != mark.document ){
        [[XVim instance].marks setMark:mark forName:@"^"];
    }
    
    [[self sourceView] xvim_escapeFromInsert];
    
    // Position for "." is after escaped from insert mode
    pos = self.sourceView.insertionPoint;
    mark = XVimMakeMark([self.sourceView.textStorage lineNumber:pos], [self.sourceView.textStorage columnNumber:pos], self.sourceView.documentURL.path);
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
    SEL keySelector = [keyStroke selectorForInstance:self];
    if (keySelector){
        nextEvaluator = [self performSelector:keySelector];
    }else if(self.movementKeyPressed){
        // Flag movement key as not pressed until the next movement key is pressed
        self.movementKeyPressed = NO;
        
        // Store off the new start range
        self.startRange = [[self sourceView] selectedRange];
    }
    
    if (nextEvaluator == self && nil == keySelector){
        NSEvent *event = [keyStroke toEventwithWindowNumber:0 context:nil];
        if (_oneCharMode) {
            if( ![self.sourceView xvim_replaceCharacters:keyStroke.character count:[self numericArg]] ){
                nextEvaluator = [XVimEvaluator invalidEvaluator];
            }else{
                nextEvaluator = nil;
            }
        } else if ([self windowShouldReceive:keySelector]) {
            // Here we pass the key input to original text view.
            // The input coming to this method is already handled by "Input Method"
            // and the input maight be non ascii like 'あ'
            if( keyStroke.modifier == 0 && isPrintable(keyStroke.character)){
                [self.sourceView insertText:keyStroke.xvimString];
            }else{
                [self.sourceView interpretKeyEvents:[NSArray arrayWithObject:event]];
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

- (void)C_yC_eHelper:(BOOL)handlingC_y {
    NSUInteger currentCursorIndex = [self.sourceView selectedRange].location;
    NSUInteger currentColumnIndex = [self.sourceView.textStorage columnNumber:currentCursorIndex];
    NSUInteger newCharIndex;
    if (handlingC_y) {
        newCharIndex = [self.sourceView.textStorage prevLine:currentCursorIndex column:currentColumnIndex count:[self numericArg] option:MOTION_OPTION_NONE];
    } else {
        newCharIndex = [self.sourceView.textStorage nextLine:currentCursorIndex column:currentColumnIndex count:[self numericArg] option:MOTION_OPTION_NONE];
    }
    NSUInteger newColumnIndex = [self.sourceView.textStorage columnNumber:newCharIndex];
    NSLog(@"Old column: %ld\tNew column: %ld", currentColumnIndex, newColumnIndex);
    if (currentColumnIndex == newColumnIndex) {
        unichar u = [[[self sourceView] string] characterAtIndex:newCharIndex];
        NSString *charToInsert = [NSString stringWithFormat:@"%c", u];
        [[self sourceView] insertText:charToInsert];
    }
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
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    [[self sourceView] xvim_delete:m];
    return self;
}

@end
