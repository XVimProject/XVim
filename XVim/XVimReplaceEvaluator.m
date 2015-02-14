//
//  XVimReplaceEvaluator.m
//  XVim
//
//  Created by Martin Conte Mac Donell on 12/14/14.
//

#import "XVimReplaceEvaluator.h"
#import "XVimWindow.h"

@interface XVimInsertEvaluator ()

- (NSString*)insertedText;
- (BOOL)windowShouldReceive:(SEL)keySelector;

@end

@interface XVimReplaceEvaluator ()

@property (nonatomic, assign) BOOL oneCharMode;

@end

@implementation XVimReplaceEvaluator

- (float)insertionPointHeightRatio{
    return 0.25;
}

- (float)insertionPointWidthRatio{
    return 1.0;
}

- (float)insertionPointAlphaRatio{
    return 0.5;
}

- (id)initWithWindow:(XVimWindow*)window oneCharMode:(BOOL)oneCharMode mode:(XVimInsertionPoint)mode{
    self = [super initWithWindow:window mode:mode];
    if (self) {
        _oneCharMode = oneCharMode;
    }
    return self;
}

- (NSString*)modeString{
    return self.oneCharMode ? @"" :  @"-- REPLACE --";
}

- (void)repeatBlockText{
    NSString *text = [self insertedText];
    NSTextView *sourceView = [self sourceView];
    
    for (NSUInteger i = 0 ; i < [self numericArg]-1; i++) {
        [sourceView insertText:text replacementRange:NSMakeRange(self.sourceView.insertionPoint, text.length)];
    }
}

- (void)didEndHandler {
    [super didEndHandler];

    NSUndoManager *undoManager = [[self sourceView] undoManager];
    [undoManager endUndoGrouping];
    [undoManager setGroupsByEvent:YES];
}

- (void)becameHandler {
    [super becameHandler];

    NSUndoManager *undoManager = [[self sourceView] undoManager];
    [undoManager setGroupsByEvent:NO];
    [undoManager beginUndoGrouping];
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
        keySelector = nil;
    }

    if (nextEvaluator == self && nil == keySelector) {
        if (self.oneCharMode || [self windowShouldReceive:keySelector]) {
            // Here we pass the key input to original text view.
            // The input coming to this method is already handled by "Input Method"
            // and the input maight be non ascii like 'あ'
            if (self.oneCharMode || keyStroke.isPrintable) {
                if (!keyStroke.isPrintable) {
                    nextEvaluator = [XVimEvaluator invalidEvaluator];
                } else if (![self.sourceView xvim_replaceCharacters:keyStroke.character count:1]) {
                    nextEvaluator = [XVimEvaluator invalidEvaluator];
                } else if (self.oneCharMode) {
                    nextEvaluator = nil;
                }
            } else {
                NSEvent *event = [keyStroke toEventwithWindowNumber:0 context:nil];
                [self.sourceView interpretKeyEvents:[NSArray arrayWithObject:event]];
            }
        }
    }
    return nextEvaluator;
}

@end
