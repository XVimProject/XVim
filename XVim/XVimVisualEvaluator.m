//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimVisualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimEqualEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimYankEvaluator.h"
#import "DVTSourceTextView.h"
#import "XVimKeymapProvider.h"

@implementation XVimVisualEvaluator 

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return _insertion;
}

- (id)initWithMode:(VISUAL_MODE)mode{ 
    self = [super init];
    if (self) {
        _mode = mode;
    }
    return self;
}

- (XVimEvaluator*)defaultNextEvaluatorWithXVim:(XVimWindow*)window
{
    // This is quick hack. When unsupported keys are pressed in Visual mode we have to set selection
    // because in "eval::" method we cancel the selection temporarily to handle motion.
    // Because methods handles supporeted keys call motionFixedFrom:To: method to update the selection
    // we do not need to call updateSelection.
    // Since this method is called when unsupported keys are pressed I use here to call updateSelection but its not clear why we call this here.
    // We should make another process for this.
    [self updateSelectionForXVim:window]; 
    return self;
}

- (XVIM_MODE)becameHandlerInWindow:(XVimWindow*)window{
    DVTSourceTextView* view = (DVTSourceTextView*)[window sourceView];
    NSRange cur = [view selectedRange];
    _begin = cur.location;
    _insertion = cur.location + cur.length;
    if( _mode == MODE_CHARACTER ){
        [view setSelectedRangeWithBoundsCheck:cur.location To:cur.location+1];
    }
    if( _mode == MODE_LINE ){
        NSUInteger head = [view headOfLine:cur.location];
        NSUInteger end = [view endOfLine:cur.location];
        if( NSNotFound != head && NSNotFound != end ){
            [view setSelectedRangeWithBoundsCheck:head To:end+1];
        }else{
            [view setSelectedRangeWithBoundsCheck:cur.location To:cur.location+1];
        }
    }
    
    return MODE_VISUAL;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_VISUAL];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    DVTSourceTextView* v = [window sourceView];
    [v setSelectedRange:NSMakeRange(_insertion, 0)]; // temporarily cancel the current selection
    [v adjustCursorPosition];
    XVimEvaluator *nextEvaluator = [super eval:keyStroke inWindow:window];
    if (nextEvaluator == self){
        [self updateSelectionForXVim:window];   
    }
    return nextEvaluator;
}


- (void)updateSelectionForXVim:(XVimWindow*)window
{
    NSTextView* view = [window sourceView];
    if( _mode == MODE_CHARACTER ){
        _selection_begin = _begin;
        _selection_end = _insertion;
    }else if( _mode == MODE_LINE ){
        NSUInteger begin = _begin;
        NSUInteger end = _insertion;
        if( _begin > _insertion ){
            begin = _insertion;
            end = _begin;
        }
        _selection_begin = [view headOfLine:begin];
        if( NSNotFound == _selection_begin ){
            _selection_begin = begin;
        }
        _selection_end = [view tailOfLine:end];
    }else if( _mode == MODE_BLOCK){
        // later
    }
    [view setSelectedRangeWithBoundsCheck:_selection_begin To:_selection_end+1];
	[view scrollTo:[window cursorLocation]];
}

- (XVimEvaluator*)C_b:(XVimWindow*)window{
    _insertion = [[window sourceView] pageBackward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:window];
    return self;
}

- (XVimEvaluator*)C_d:(XVimWindow*)window{
    _insertion = [[window sourceView] halfPageForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:window];
    return self;
}

- (XVimEvaluator*)C_f:(XVimWindow*)window{
    _insertion = [[window sourceView] pageForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:window];
    return self;
}


- (XVimEvaluator*)c:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:YES];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:YES];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)d:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}


- (XVimEvaluator*)D:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:LINEWISE inWindow:window];
    
}

- (XVimEvaluator*)u:(XVimWindow*)window {
	[self updateSelectionForXVim:window];
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	[self updateSelectionForXVim:window];
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view uppercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)C_u:(XVimWindow*)window{
    _insertion = [[window sourceView] halfPageBackward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:window];
    return self;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    if( _mode == MODE_CHARACTER ){
        // go to normal mode
        return  [self ESC:window];
    }
    _mode = MODE_CHARACTER;
    [self updateSelectionForXVim:window];
    return self;
}

- (XVimEvaluator*)V:(XVimWindow*)window{
    if( MODE_LINE == _mode ){
        // go to normal mode
        return  [self ESC:window];
    }
    _mode = MODE_LINE;
    [self updateSelectionForXVim:window];
    return self;
}

- (XVimEvaluator*)x:(XVimWindow*)window{
    return [self d:window];
}

- (XVimEvaluator*)X:(XVimWindow*)window{
    return [self D:window];
}

- (XVimEvaluator*)y:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] init];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)EQUAL:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
	
	XVimOperatorAction *operatorAction = [[XVimEqualAction alloc] init];
    XVimEqualEvaluator *evaluator = [[XVimEqualEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];

    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}


- (XVimEvaluator*)ESC:(XVimWindow*)window{
    [[window sourceView] setSelectedRange:NSMakeRange(_insertion, 0)];
    return nil;
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
    DVTSourceTextView* view = (DVTSourceTextView*)[window sourceView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight:self];
    }
    NSRange r = [[window sourceView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}


- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window{
    [self updateSelectionForXVim:window];
    DVTSourceTextView* view = [window sourceView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft:self];
    }
    NSRange r = [[window sourceView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	[self updateSelectionForXVim:window];
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view toggleCaseForRange:r];
	return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    //TODO: Handle type
    // Expand current selected range (_begin, _insertion )
    _insertion = to;
    [self updateSelectionForXVim:window];
    return self;
}
@end

