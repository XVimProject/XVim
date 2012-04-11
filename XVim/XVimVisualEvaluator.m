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
#import "XVimTextObjectEvaluator.h"
#import "XVimSelectAction.h"

@implementation XVimVisualEvaluator 

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return _insertion;
}

- (id)initWithMode:(VISUAL_MODE)mode{ 
    self = [super init];
    if (self) {
        _mode = mode;
		_begin = NSNotFound;
    }
    return self;
}

- (id)initWithMode:(VISUAL_MODE)mode withRange:(NSRange)range {
	if (self = [self initWithMode:mode]) {
		_begin = range.location;
		_insertion = MAX(_begin, range.location + range.length - 1);
	}
	return self;
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window
{
    // This is quick hack. When unsupported keys are pressed in Visual mode we have to set selection
    // because in "eval::" method we cancel the selection temporarily to handle motion.
    // Because methods handles supporeted keys call motionFixedFrom:To: method to update the selection
    // we do not need to call updateSelection.
    // Since this method is called when unsupported keys are pressed I use here to call updateSelection but its not clear why we call this here.
    // We should make another process for this.
    [self updateSelectionInWindow:window]; 
    return self;
}

- (void)becameHandlerInWindow:(XVimWindow*)window{
	
	if (_begin == NSNotFound)
	{
		DVTSourceTextView* view = (DVTSourceTextView*)[window sourceView];
		NSRange cur = [view selectedRange];
		if( _mode == MODE_CHARACTER ){
			_begin = cur.location;
			_insertion = cur.location;
		}
		if( _mode == MODE_LINE ){
			NSUInteger head = [view headOfLine:cur.location];
			NSUInteger end = [view endOfLine:cur.location];
			if( NSNotFound != head && NSNotFound != end ){
				_begin = head;
				_insertion = end;
			}else{
				_begin = cur.location;
				_insertion = cur.location;
			}
		}
	}
	
	[self updateSelectionInWindow:window];
}
    
- (XVIM_MODE)mode {
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
    if (nextEvaluator && nextEvaluator.mode == MODE_VISUAL) {
        [self updateSelectionInWindow:window];   
    }
    return nextEvaluator;
}


- (void)updateSelectionInWindow:(XVimWindow*)window
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
    [self updateSelectionInWindow:window];
    return self;
}

- (XVimEvaluator*)C_d:(XVimWindow*)window{
    _insertion = [[window sourceView] halfPageForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionInWindow:window];
    return self;
}

- (XVimEvaluator*)C_f:(XVimWindow*)window{
    _insertion = [[window sourceView] pageForward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionInWindow:window];
    return self;
}

- (XVimEvaluator*)a:(XVimWindow*)window
{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimSelectAction alloc] init];
	XVimEvaluator *evaluator = [[XVimTextObjectEvaluator alloc] initWithOperatorAction:action 
																			withParent:self
																				repeat:1 
																			 inclusive:YES];
	return evaluator;
}

- (XVimEvaluator*)c:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:YES];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action 
																			  withParent:self
																				  repeat:[self numericArg] 
																  insertModeAtCompletion:YES];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)d:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action 
																			  withParent:self
																				  repeat:[self numericArg] 
																  insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}


- (XVimEvaluator*)D:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithOperatorAction:action 
																			  withParent:self
																				  repeat:[self numericArg] 
																  insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:LINEWISE inWindow:window];
    
}

- (XVimEvaluator*)i:(XVimWindow*)window
{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimSelectAction alloc] init];
	XVimEvaluator *evaluator = [[XVimTextObjectEvaluator alloc] initWithOperatorAction:action 
																			withParent:self
																				repeat:1 
																			 inclusive:NO];
	return evaluator;
}

- (XVimEvaluator*)u:(XVimWindow*)window {
	[self updateSelectionInWindow:window];
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	[self updateSelectionInWindow:window];
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view uppercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)C_u:(XVimWindow*)window{
    _insertion = [[window sourceView] halfPageBackward:[[window sourceView] selectedRange].location count:[self numericArg]];
    [self updateSelectionInWindow:window];
    return self;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    if( _mode == MODE_CHARACTER ){
        // go to normal mode
        return  [self ESC:window];
    }
    _mode = MODE_CHARACTER;
    [self updateSelectionInWindow:window];
    return self;
}

- (XVimEvaluator*)V:(XVimWindow*)window{
    if( MODE_LINE == _mode ){
        // go to normal mode
        return  [self ESC:window];
    }
    _mode = MODE_LINE;
    [self updateSelectionInWindow:window];
    return self;
}

- (XVimEvaluator*)x:(XVimWindow*)window{
    return [self d:window];
}

- (XVimEvaluator*)X:(XVimWindow*)window{
    return [self D:window];
}

- (XVimEvaluator*)y:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] init];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithOperatorAction:operatorAction 
																		  withParent:self
																			  repeat:[self numericArg]];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)EQUAL:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	
	XVimOperatorAction *operatorAction = [[XVimEqualAction alloc] init];
    XVimEqualEvaluator *evaluator = [[XVimEqualEvaluator alloc] initWithOperatorAction:operatorAction 
																			withParent:self
																				repeat:[self numericArg]];

    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}


- (XVimEvaluator*)ESC:(XVimWindow*)window{
    [[window sourceView] setSelectedRange:NSMakeRange(_insertion, 0)];
    return nil;
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
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
    [self updateSelectionInWindow:window];
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
	[self updateSelectionInWindow:window];
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
    [self updateSelectionInWindow:window];
    return self;
}
@end

