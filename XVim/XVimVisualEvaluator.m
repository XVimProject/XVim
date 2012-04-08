//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimVisualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimEqualEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimYankEvaluator.h"
#import "DVTSourceTextView.h"

@implementation XVimVisualEvaluator 

- (NSUInteger)insertionPoint:(XVim*)xvim
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

- (XVimEvaluator*)defaultNextEvaluatorWithXVim:(XVim*)xvim
{
    // This is quick hack. When unsupported keys are pressed in Visual mode we have to set selection
    // because in "eval::" method we cancel the selection temporarily to handle motion.
    // Because methods handles supporeted keys call motionFixedFrom:To: method to update the selection
    // we do not need to call updateSelection.
    // Since this method is called when unsupported keys are pressed I use here to call updateSelection but its not clear why we call this here.
    // We should make another process for this.
    [self updateSelectionForXVim:xvim]; 
    return self;
}

- (XVIM_MODE)becameHandler:(XVim *)xvim{
    DVTSourceTextView* view = (DVTSourceTextView*)[xvim sourceView];
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

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
	return keymaps[MODE_VISUAL];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke XVim:(XVim*)xvim{
    DVTSourceTextView* v = [xvim sourceView];
    [v setSelectedRange:NSMakeRange(_insertion, 0)]; // temporarily cancel the current selection
    [v adjustCursorPosition];
    XVimEvaluator *nextEvaluator = [super eval:keyStroke XVim:xvim];
    if (nextEvaluator == self){
        [self updateSelectionForXVim:xvim];   
    }
    return nextEvaluator;
}


- (void)updateSelectionForXVim:(XVim*)xvim
{
    NSTextView* view = [xvim sourceView];
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
    [view scrollToCursor];
}

- (XVimEvaluator*)C_b:(XVim*)xvim{
    _insertion = [[xvim sourceView] pageBackward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:xvim];
    return self;
}

- (XVimEvaluator*)C_d:(XVim*)xvim{
    _insertion = [[xvim sourceView] halfPageForward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:xvim];
    return self;
}

- (XVimEvaluator*)C_f:(XVim*)xvim{
    _insertion = [[xvim sourceView] pageForward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:xvim];
    return self;
}


- (XVimEvaluator*)c:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:YES];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:YES];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)d:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}


- (XVimEvaluator*)D:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:LINEWISE XVim:xvim];
    
}

- (XVimEvaluator*)u:(XVim*)xvim {
	[self updateSelectionForXVim:xvim];
	NSTextView *view = [xvim sourceView];
	NSRange r = [view selectedRange];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)U:(XVim*)xvim {
	[self updateSelectionForXVim:xvim];
	NSTextView *view = [xvim sourceView];
	NSRange r = [view selectedRange];
	[view uppercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)C_u:(XVim*)xvim{
    _insertion = [[xvim sourceView] halfPageBackward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionForXVim:xvim];
    return self;
}

- (XVimEvaluator*)v:(XVim*)xvim{
    if( _mode == MODE_CHARACTER ){
        // go to normal mode
        return  [self ESC:xvim];
    }
    _mode = MODE_CHARACTER;
    [self updateSelectionForXVim:xvim];
    return self;
}

- (XVimEvaluator*)V:(XVim*)xvim{
    if( MODE_LINE == _mode ){
        // go to normal mode
        return  [self ESC:xvim];
    }
    _mode = MODE_LINE;
    [self updateSelectionForXVim:xvim];
    return self;
}

- (XVimEvaluator*)x:(XVim*)xvim{
    return [self d:xvim];
}

- (XVimEvaluator*)X:(XVim*)xvim{
    return [self D:xvim];
}

- (XVimEvaluator*)y:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] init];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)EQUAL:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
	
	XVimOperatorAction *operatorAction = [[XVimEqualAction alloc] init];
    XVimEqualEvaluator *evaluator = [[XVimEqualEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];

    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}


- (XVimEvaluator*)ESC:(XVim*)xvim{
    [[xvim sourceView] setSelectedRange:NSMakeRange(_insertion, 0)];
    return nil;
}

- (XVimEvaluator*)GREATERTHAN:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
    DVTSourceTextView* view = (DVTSourceTextView*)[xvim sourceView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight:self];
    }
    NSRange r = [[xvim sourceView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}


- (XVimEvaluator*)LESSTHAN:(XVim*)xvim{
    [self updateSelectionForXVim:xvim];
    DVTSourceTextView* view = [xvim sourceView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft:self];
    }
    NSRange r = [[xvim sourceView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}

- (XVimEvaluator*)TILDE:(XVim*)xvim {
	[self updateSelectionForXVim:xvim];
	NSTextView *view = [xvim sourceView];
	NSRange r = [view selectedRange];
	[view toggleCaseForRange:r];
	return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
    //TODO: Handle type
    // Expand current selected range (_begin, _insertion )
    _insertion = to;
    [self updateSelectionForXVim:xvim];
    return self;
}
@end

