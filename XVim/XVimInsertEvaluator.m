//
//  XVimInsertEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimInsertEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimKeyStroke.h"
#import "DVTSourceTextView.h"
#import "DVTCompletionController.h"
#import "XVimKeymapProvider.h"

@interface XVimInsertEvaluator()
@property (nonatomic) NSRange startRange;
@property (nonatomic) BOOL movementKeyPressed;
@property (nonatomic, strong) NSString *lastInsertedText;
@property (nonatomic, readonly, strong) NSArray *cancelKeys;
@property (nonatomic, readonly, strong) NSArray *movementKeys;
@end

@implementation XVimInsertEvaluator

@synthesize startRange = _startRange;
@synthesize cancelKeys = _cancelKeys;
@synthesize movementKeys = _movementKeys;
@synthesize lastInsertedText = _lastInsertedText;
@synthesize movementKeyPressed = _movementKeyPressed;

- (id)initWithRepeat:(NSUInteger)repeat{
    return [self initOneCharMode:FALSE withRepeat:repeat];
}

- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
        _lastInsertedText = @"";
        _oneCharMode = oneCharMode;
        _movementKeyPressed = NO;
        _insertedEventsAbort = NO;
        _cancelKeys = [NSArray arrayWithObjects:
                       [NSValue valueWithPointer:@selector(ESC:)],
                       [NSValue valueWithPointer:@selector(C_LSQUAREBRACKET:)],
                       [NSValue valueWithPointer:@selector(C_c:)],
                       nil];
        _movementKeys = [NSArray arrayWithObjects:
                         [NSValue valueWithPointer:@selector(Up:)],
                         [NSValue valueWithPointer:@selector(Down:)],
                         [NSValue valueWithPointer:@selector(Left:)],
                         [NSValue valueWithPointer:@selector(Right:)],
                         nil];
    }
    return self;
}

- (XVIM_MODE)becameHandlerInWindow:(XVimWindow*)window{
    self.startRange = [window selectedRange];
    return MODE_INSERT;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_INSERT];
}

- (NSString*)getInsertedTextInWindow:(XVimWindow*)window {
    NSRange endRange = [window selectedRange];
    NSRange textRange;
    if (endRange.location > self.startRange.location){
        textRange = NSMakeRange(self.startRange.location, endRange.location - self.startRange.location);
    }else{
        textRange = NSMakeRange(endRange.location, self.startRange.location - endRange.location);
    }
    
    NSString *text = [[window sourceText] substringWithRange:textRange];
    return text;
    
}

- (void)recordTextIntoRegister:(XVimRegister*)xregister inWindow:(XVimWindow*)window {
    NSString *text = [self getInsertedTextInWindow:window];
    if (text.length > 0){
        [xregister appendText:text];
    }
}

- (void)onMovementKeyPressed:(XVimWindow*)window {
    _insertedEventsAbort = YES;
    if (!self.movementKeyPressed){
        self.movementKeyPressed = YES;
        
        // Store off any needed text
        self.lastInsertedText = [self getInsertedTextInWindow:window];
        [self recordTextIntoRegister:window.recordingRegister inWindow:window];
    }
    
    // Store off the new start range
    self.startRange = [window selectedRange];
}

- (void)onFinishInsert:(XVimWindow*)window {
	DVTSourceTextView *sourceView = [window sourceView];
	
    if( !_insertedEventsAbort ){
        NSString *text = [self getInsertedTextInWindow:window];
        for( int i = 0 ; i < _repeat-1; i++ ){
            [sourceView insertText:text];
        }
    }
    
    // Store off any needed text
    if (!self.movementKeyPressed){
        [self recordTextIntoRegister:window.recordingRegister inWindow:window];
        [self recordTextIntoRegister:[[XVim instance] findRegister:@"repeat"] inWindow:window];
    }else if(self.lastInsertedText.length > 0){
        [[[XVim instance] findRegister:@"repeat"] appendText:self.lastInsertedText];
    }
    [[sourceView completionController] hideCompletions];
	
	// Set selection to one-before-where-we-were
	NSUInteger insertionPoint = [self insertionPointInWindow:window];
	NSUInteger headOfLine = [sourceView headOfLine:insertionPoint];
	if (insertionPoint > 0 && headOfLine != insertionPoint && headOfLine != NSNotFound)
	{
		--insertionPoint;
	}
	[sourceView setSelectedRange:NSMakeRange(insertionPoint, 0)];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    XVimEvaluator *nextEvaluator = self;
    SEL keySelector = [keyStroke selectorForInstance:self];
    if (keySelector){
        nextEvaluator = [self performSelector:keySelector withObject:window];
    }else if(self.movementKeyPressed){
        // Flag movement key as not pressed until the next movement key is pressed
        self.movementKeyPressed = NO;
        
        // Store off the new start range
        self.startRange = [window selectedRange];
    }
    
    if (nextEvaluator != nil){
        NSEvent *event = [keyStroke toEvent];
        if (_oneCharMode == TRUE) {
            NSRange save = [[window sourceView] selectedRange];
            for (NSUInteger i = 0; i < _repeat; ++i) {
                [[window sourceView] deleteForward:self];
                [[window sourceView] keyDown_:event];
                
                save.location += 1;
                [[window sourceView] setSelectedRange:save];
            }
            save.location -= 1;
            [[window sourceView] setSelectedRange:save];
            nextEvaluator = nil;
        } else {
            [[window sourceView] keyDown_:event];
        }
    }
    
    if( self != nextEvaluator ){
        [[window sourceView] adjustCursorPosition];
    }
    return nextEvaluator;
}

- (XVimEvaluator*)ESC:(XVimWindow*)window{
    [self onFinishInsert:window];
    return nil;
}

- (XVimEvaluator*)C_LSQUAREBRACKET:(XVimWindow*)window{
    [self onFinishInsert:window];
    return nil;
}

- (XVimEvaluator*)C_c:(XVimWindow*)window{
    [self onFinishInsert:window];
    return nil;
}

- (XVimEvaluator*)Up:(XVimWindow*)window{
    [self onMovementKeyPressed:window];
    return self;
}

- (XVimEvaluator*)Down:(XVimWindow*)window{
    [self onMovementKeyPressed:window];
    return self;
}

- (XVimEvaluator*)Left:(XVimWindow*)window{
    [self onMovementKeyPressed:window];
    return self;
}

- (XVimEvaluator*)Right:(XVimWindow*)window{
    [self onMovementKeyPressed:window];
    return self;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    // Do not record key strokes for insert. Instead we will directly append the inserted text into the register.
    NSValue *keySelector = [NSValue valueWithPointer:[keyStroke selectorForInstance:self]];
    if ([self.cancelKeys containsObject:keySelector]){
        return REGISTER_APPEND;
    }else if (xregister.isReadOnly == NO && ([self.movementKeys containsObject:keySelector] || _oneCharMode)){
        return REGISTER_APPEND;
    }else if (xregister.isRepeat && _oneCharMode){
        return REGISTER_APPEND;
    }
    
    return REGISTER_IGNORE;
}

@end
