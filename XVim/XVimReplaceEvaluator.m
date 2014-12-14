//
//  XVimReplaceEvaluator.m
//  XVim
//
//  Created by Martin Conte Mac Donell on 12/14/14.
//

#import "XVimReplaceEvaluator.h"
#import "XVimWindow.h"

@interface XVimInsertEvaluator()

@property (nonatomic) NSRange startRange;
@property (nonatomic) BOOL movementKeyPressed;

- (NSString*)insertedText;
- (BOOL)windowShouldReceive:(SEL)keySelector;

@end

@implementation XVimReplaceEvaluator {
    BOOL _oneCharMode;
}

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
	return @"-- REPLACE --";
}

- (void)abc {
    if (_oneCharMode) {
        return;
    }

    NSString *text = [self insertedText];
    NSTextView *sourceView = [self sourceView];
    
    for (int i = 0 ; i < [self numericArg]-1; i++) {
        [sourceView insertText:text replacementRange:NSMakeRange(self.sourceView.insertionPoint, text.length)];
    }
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
        if (_oneCharMode || [self windowShouldReceive:keySelector]) {
            // Here we pass the key input to original text view.
            // The input coming to this method is already handled by "Input Method"
            // and the input maight be non ascii like 'あ'
            if( _oneCharMode || (keyStroke.modifier == 0 && isPrintable(keyStroke.character))){
                if (![self.sourceView xvim_replaceCharacters:keyStroke.character count:1]) {
                    nextEvaluator = [XVimEvaluator invalidEvaluator];
                } else if (_oneCharMode) {
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
