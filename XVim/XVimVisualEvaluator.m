//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimVisualEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
#import "Logger.h"
#import "XVimEqualEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimYankEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimSelectAction.h"
#import "XVimGVisualEvaluator.h"
#import "XVimRegisterEvaluator.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimOptions.h"
#import "XVim.h"

@interface XVimVisualEvaluator(){
    
}
- (XVimEvaluator*)ESC:(XVimWindow*)window;
@end
@implementation XVimVisualEvaluator 

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return _insertion;
}

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode
{ 
    self = [super initWithContext:context];
    if (self) {
        _mode = mode;
		_begin = NSNotFound;
		_operationRange.location = NSNotFound;
    }
    return self;
}

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode 
			withRange:(NSRange)range 
{
	if (self = [self initWithContext:context mode:mode]) {
		_begin = NSNotFound;
		_operationRange = range;
	}
	return self;
}


static NSString* MODE_STRINGS[] = {@"-- VISUAL --", @"-- VISUAL LINE --", @"-- VISUAL BLOCK --"};

- (NSString*)modeString
{
	return MODE_STRINGS[_mode];
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
	
	DVTSourceTextView* view = (DVTSourceTextView*)[window sourceView];
	
	// Select operation range passed to constructor
	if (_operationRange.location != NSNotFound) {
		if (_mode == MODE_CHARACTER) {
			_begin = _operationRange.location;
			_insertion = MAX(_begin, _operationRange.location + _operationRange.length - 1);
		} else {
			_begin = [view positionAtLineNumber:_operationRange.location];
			_insertion = [view positionAtLineNumber:_operationRange.location + _operationRange.length];
		}
	} 
	
	if (_begin == NSNotFound) {
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
	[super becameHandlerInWindow:window];
}
    
- (void)didEndHandlerInWindow:(XVimWindow*)window
{
	[super didEndHandlerInWindow:window];
	[[[XVim instance] repeatRegister] setVisualMode:_mode withRange:_operationRange];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_VISUAL];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return NO;
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
    XVimSourceView* sourceView = [window sourceView];
	
	NSUInteger glyphIndex = [self insertionPointInWindow:window];
	NSRect glyphRect = [sourceView boundingRectForGlyphIndex:glyphIndex];
	
	[[[sourceView insertionPointColor] colorWithAlphaComponent:0.5] set];
	NSRectFillUsingOperation(glyphRect, NSCompositeSourceOver);
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    XVimSourceView* v = [window sourceView];
    [v setSelectedRange:NSMakeRange(_insertion, 0)]; // temporarily cancel the current selection
    [v adjustCursorPosition];
    XVimEvaluator *nextEvaluator = [super eval:keyStroke inWindow:window];
    if ([nextEvaluator isRelatedTo:self]) {
        [self updateSelectionInWindow:window];   
    }
    return nextEvaluator;
}


- (void)updateSelectionInWindow:(XVimWindow*)window
{
    XVimSourceView* view = [window sourceView];
    if( _mode == MODE_CHARACTER ){
		
		if (_begin <= _insertion)
		{
			_selection_begin = _begin;
			_selection_end = _insertion;
		}
		else
		{
			_selection_begin = _insertion;
			_selection_end = _begin;
		}
		
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
	[view scrollTo:[window insertionPoint]];
	
	if (_mode == MODE_CHARACTER) {
		_operationRange = [[window sourceView] selectedRange];
	} else {
		NSRange selectedRange = [[window sourceView] selectedRange];
		NSUInteger startLine = [view lineNumber:selectedRange.location];
		NSUInteger endLine = [view lineNumber:selectedRange.location + selectedRange.length];
		_operationRange = NSMakeRange(startLine, endLine - startLine);
	}
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
	XVimEvaluator *evaluator = [[XVimTextObjectEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"a"]
																 operatorAction:action 
																	 withParent:self
																	  inclusive:YES];
	return evaluator;
}

- (XVimEvaluator*)c:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
														 insertModeAtCompletion:YES];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithContext:[self contextCopy]
																   operatorAction:action 
																	   withParent:self
														   insertModeAtCompletion:YES];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)d:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
														 insertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithContext:[self contextCopy]
																   operatorAction:action 
																	   withParent:self
														   insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}


- (XVimEvaluator*)D:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
														 insertModeAtCompletion:NO];	
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithContext:[self contextCopy]
																   operatorAction:action 
																	   withParent:self
														   insertModeAtCompletion:NO];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:LINEWISE inWindow:window];
    
}

- (XVimEvaluator*)g:(XVimWindow*)window
{
	return [[XVimGVisualEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"g"]
												  parent:self];
}

- (XVimEvaluator*)i:(XVimWindow*)window
{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *action = [[XVimSelectAction alloc] init];
	XVimEvaluator *evaluator = [[XVimTextObjectEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"i"]
																 operatorAction:action 
																	 withParent:self
																	  inclusive:NO];
	return evaluator;
}
 
- (XVimEvaluator*)m:(XVimWindow*)window{
    // 'm{letter}' sets a local mark.
	return [[XVimMarkSetEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"m"]
												  parent:self];
}

- (XVimEvaluator*)p:(XVimWindow*)window{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    // TODO: This does not work when the text is copied from line which includes EOF since it does not have newline.
    //       If we want to treat the behaviour correctly we should prepare registers to copy and create an attribute to keep 'linewise'
    XVimSourceView* view = [window sourceView];
    [self updateSelectionInWindow:window];
    // Keep currently selected string
    NSString* current = [[view string] substringWithRange:[view selectedRange]];
    [view deleteText];
    NSUInteger loc = [view selectedRange].location;
    NSString *text = [[XVim instance] pasteText:[self yankRegister]];
    if (text.length > 0){
        if (_mode == MODE_CHARACTER) {
            unichar uc = [text characterAtIndex:[text length] -1];
            if ([[NSCharacterSet newlineCharacterSet] characterIsMember:uc]) {
                if( [view isBlankLine:loc] && ![view isEOF:loc]){
                    [view setSelectedRange:NSMakeRange(loc+1,0)];
                }else{
                    [view insertNewline];
                }
            }
        }
        
        for(NSUInteger i = 0; i < [self numericArg]; i++ ){
            [view insertText:text];
        }
        
        [[XVim instance] onDeleteOrYank:[self yankRegister] text:current];
    }
    return nil;
}

- (XVimEvaluator*)P:(XVimWindow*)window{
    // Looks P works as p in Visual Mode.. right?
    return [self p:window];
}

- (XVimEvaluator*)s:(XVimWindow*)window {
	// As far as I can tell this is equivalent to change
	return [self c:window];
}


- (XVimEvaluator*)u:(XVimWindow*)window {
	[self updateSelectionInWindow:window];
	XVimSourceView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	[self updateSelectionInWindow:window];
	XVimSourceView *view = [window sourceView];
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
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] initWithYankRegister:[self yankRegister]];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithContext:[self contextCopy]
															   operatorAction:operatorAction 
																   withParent:self];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)Y:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] initWithYankRegister:[self yankRegister]];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithContext:[self contextCopy]
															   operatorAction:operatorAction 
																   withParent:self];
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:LINEWISE inWindow:window];
}

- (XVimEvaluator*)DQUOTE:(XVimWindow*)window{
    XVimEvaluator* eval = [[XVimRegisterEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"\""]
																  parent:self
															  completion:^ XVimEvaluator* (NSString* rname, XVimEvaluatorContext *context)  
						   {
							   XVimRegister *xregister = [[XVim instance] findRegister:rname];
							   if (xregister.isReadOnly == NO || [xregister.displayName isEqualToString:@"%"] ){
								   [context setYankRegister:xregister];
								   [context appendArgument:rname];
								   return [self withNewContext:context];
							   }
							   
							   [[XVim instance] ringBell];
							   return nil;
						   }];
	return eval;
}

- (XVimEvaluator*)EQUAL:(XVimWindow*)window{
    [self updateSelectionInWindow:window];
	
	XVimOperatorAction *operatorAction = [[XVimEqualAction alloc] init];
    XVimEqualEvaluator *evaluator = [[XVimEqualEvaluator alloc] initWithContext:[self contextCopy]
																 operatorAction:operatorAction 
																	 withParent:self];

    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}


- (XVimEvaluator*)ESC:(XVimWindow*)window{
    [[window sourceView] setSelectedRange:NSMakeRange(_insertion, 0)];
    return nil;
}

- (XVimEvaluator*)C_c:(XVimWindow*)window{
  return [self ESC:window];
}

- (XVimEvaluator*)C_LSQUAREBRACKET:(XVimWindow*)window{
  return [self ESC:window];
}

  - (XVimEvaluator*)COLON:(XVimWindow*)window{
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithContext:[self contextCopy]
																	 parent:self 
															   firstLetter:@":'<,'>" 
																   history:[[XVim instance] exCommandHistory]
																completion:^ XVimEvaluator* (NSString* command) 
                           {
                               XVimExCommand *excmd = [[XVim instance] excmd];
                               [excmd executeCommand:command inWindow:window];

							   XVimSourceView *sourceView = [window sourceView];
                               [sourceView setSelectedRange:NSMakeRange(_insertion, 0)];
                               return nil;
                           }
                                                                onKeyPress:nil];
	
	return eval;
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
    DVTSourceTextView* view = (DVTSourceTextView*)[window sourceView];
	
	_mode = MODE_LINE;
    [self updateSelectionInWindow:window];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight];
    }
	NSUInteger cursorLocation = [view firstNonBlankInALine:[view positionAtLineNumber:_operationRange.location]];
	[view setSelectedRangeWithBoundsCheck:cursorLocation To:cursorLocation];
    return nil;
}


- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
	
	_mode = MODE_LINE;
    [self updateSelectionInWindow:window];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft];
    }
	NSUInteger cursorLocation = [view firstNonBlankInALine:[view positionAtLineNumber:_operationRange.location]];
	[view setSelectedRangeWithBoundsCheck:cursorLocation To:cursorLocation];
    return nil;
}

- (XVimEvaluator*)executeSearch:(XVimWindow*)window firstLetter:(NSString*)firstLetter 
{
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]
																	 parent:self 
															   firstLetter:firstLetter
																   history:[[XVim instance] searchHistory]
																completion:^ XVimEvaluator* (NSString *command)
						   {
							   XVimSearch *searcher = [[XVim instance] searcher];
							   XVimSourceView *sourceView = [window sourceView];
							   NSRange found = [searcher executeSearch:command 
															   display:[command substringFromIndex:1]
																  from:[window insertionPoint] 
															  inWindow:window];
							   //Move cursor and show the found string
							   if (found.location != NSNotFound) {
                                   unichar firstChar = [command characterAtIndex:0];
                                   if (firstChar == '?'){
                                       _insertion = found.location;
                                   }else if (firstChar == '/'){
                                       _insertion = found.location + command.length - 1;
                                   }
                                   [self updateSelectionInWindow:window];
								   [sourceView scrollTo:[window insertionPoint]];
								   [sourceView showFindIndicatorForRange:found];
							   } else {
								   [window errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchDisplayString] ringBell:TRUE];
							   }
                               return self;
						   }
                                                                onKeyPress:^void(NSString *command)
                           {
                               XVimOptions *options = [[XVim instance] options];
                               if (options.incsearch){
                                   XVimSearch *searcher = [[XVim instance] searcher];
                                   XVimSourceView *sourceView = [window sourceView];
                                   NSRange found = [searcher executeSearch:command 
																   display:[command substringFromIndex:1]
																	  from:[window insertionPoint] 
																  inWindow:window];
                                   //Move cursor and show the found string
                                   if (found.location != NSNotFound) {
                                       // Update the selection while preserving the current insertion point
                                       // The insertion point will be finalized if we complete a search
                                       NSUInteger prevInsertion = _insertion;
                                       unichar firstChar = [command characterAtIndex:0];
                                       if (firstChar == '?'){
                                           _insertion = found.location;
                                       }else if (firstChar == '/'){
                                           _insertion = found.location + command.length - 1;
                                       }
                                       [self updateSelectionInWindow:window];
                                       _insertion = prevInsertion;
                                       
                                       [sourceView scrollTo:found.location];
                                       [sourceView showFindIndicatorForRange:found];
                                   }
                               }
                           }];
	return eval;
}

- (XVimEvaluator*)QUESTION:(XVimWindow*)window{
	return [self executeSearch:window firstLetter:@"?"];
}

- (XVimEvaluator*)SLASH:(XVimWindow*)window{
	return [self executeSearch:window firstLetter:@"/"];
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	[self updateSelectionInWindow:window];
	XVimSourceView *view = [window sourceView];
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
    return [self withNewContext];
}

static NSArray *_invalidRepeatKeys;
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (_invalidRepeatKeys == nil){
        _invalidRepeatKeys =
        [[NSArray alloc] initWithObjects:
         [NSValue valueWithPointer:@selector(m:)],
         [NSValue valueWithPointer:@selector(C_r:)],
         [NSValue valueWithPointer:@selector(v:)],
         [NSValue valueWithPointer:@selector(V:)],
         [NSValue valueWithPointer:@selector(C_v:)],
         [NSValue valueWithPointer:@selector(COLON:)],
         [NSValue valueWithPointer:@selector(QUESTION:)],
         [NSValue valueWithPointer:@selector(SLASH:)],
         nil];
    }
    NSValue *keySelector = [NSValue valueWithPointer:[keyStroke selectorForInstance:self]];
    if (xregister.isRepeat) {
        if ([keyStroke classImplements:[XVimVisualEvaluator class]]) {
            if ([_invalidRepeatKeys containsObject:keySelector] == NO) {
                return REGISTER_REPLACE;
            }
        }
    }
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end