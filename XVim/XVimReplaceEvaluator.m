//
//  XVimReplaceEvaluator.m
//  XVim
//
//  Created by Martin Conte Mac Donell on 12/14/14.
//

#import "XVimReplaceEvaluator.h"
#import "XVimWindow.h"

@interface XVimInsertEvaluator()

@property (nonatomic) BOOL oneCharMode;

- (NSString*)insertedText;
- (BOOL)windowShouldReceive:(SEL)keySelector;

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
        self.oneCharMode = oneCharMode;
    }
    return self;
}

- (NSString*)modeString{
    return self.oneCharMode ? @"" :  @"-- REPLACE --";
}

- (void)repeatBlockText{
    if (self.oneCharMode) {
        return;
    }

    NSString *text = [self insertedText];
    NSTextView *sourceView = [self sourceView];
    
    for (int i = 0 ; i < [self numericArg]-1; i++) {
        [sourceView insertText:text replacementRange:NSMakeRange(self.sourceView.insertionPoint, text.length)];
    }
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    SEL keySelector = [keyStroke selectorForInstance:self];
    XVimEvaluator *nextEvaluator = keySelector ? [self performSelector:keySelector] : self;

    if (nextEvaluator == self && nil == keySelector){
        if (self.oneCharMode || [self windowShouldReceive:keySelector]) {
            // Here we pass the key input to original text view.
            // The input coming to this method is already handled by "Input Method"
            // and the input maight be non ascii like 'あ'
            if (self.oneCharMode || (keyStroke.modifier == 0 && isPrintable(keyStroke.character))) {
                if (![self.sourceView xvim_replaceCharacters:keyStroke.character count:1]) {
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
