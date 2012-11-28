//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimInsertEvaluator.h"
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

/*
- (NSUInteger)insertionPointInWindow:(XVimWindow*)window {
    return _insertion;
}
*/

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode
{ 
    self = [super initWithContext:context];
    if (self) {
        _mode = mode;
		_operationRange.location = NSNotFound;
    }
    return self;
}

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode 
			withRange:(NSRange)range 
{
	if (self = [self initWithContext:context mode:mode]) {
		_operationRange = range;
	}
	return self;
}


static NSString* MODE_STRINGS[] = {@"", @"-- VISUAL --", @"-- VISUAL LINE --", @"-- VISUAL BLOCK --"};

- (NSString*)modeString {
	return MODE_STRINGS[_mode];
}

- (void)becameHandlerInWindow:(XVimWindow*)window{
	XVimSourceView* view = [window sourceView];
    [view changeSelectionMode:_mode];
    /*
	// Select operation range passed to constructor
	if (_operationRange.location != NSNotFound) {
		if (_mode == MODE_CHARACTER) {
            view.selectionBegin = _operationRange.location;
            view.insertionPoint = MAX(view.selectionBegin, _operationRange.location + _operationRange.length - 1);
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
     */
}
    
- (void)didEndHandlerInWindow:(XVimWindow*)window {
	[super didEndHandlerInWindow:window];
	[[[XVim instance] repeatRegister] setVisualMode:_mode withRange:_operationRange];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_VISUAL];
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window {
    XVimSourceView* sourceView = [window sourceView];
	
	NSUInteger glyphIndex = [window insertionPoint];
	NSRect glyphRect = [sourceView boundingRectForGlyphIndex:glyphIndex];
	
	[[[sourceView insertionPointColor] colorWithAlphaComponent:0.5] set];
	NSRectFillUsingOperation(glyphRect, NSCompositeSourceOver);
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    XVimEvaluator *nextEvaluator = [super eval:keyStroke inWindow:window];
    return nextEvaluator;
}

- (XVimEvaluator*)a:(XVimWindow*)window {
	XVimOperatorAction *action = [[XVimSelectAction alloc] init];
	XVimEvaluator *evaluator = [[XVimTextObjectEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"a"]
																 operatorAction:action 
																	 withParent:self
																	  inclusive:YES];
	return evaluator;
}

- (XVimEvaluator*)c:(XVimWindow*)window{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    [[window sourceView] change:m];
    return [[[XVimInsertEvaluator alloc] initWithContext:[self contextCopy]] autorelease];
}

- (XVimEvaluator*)d:(XVimWindow*)window{
    [[window sourceView] delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
    return nil;
}

- (XVimEvaluator*)D:(XVimWindow*)window{
    [[window sourceView] delete:XVIM_MAKE_MOTION(MOTION_NONE, LINEWISE, MOTION_OPTION_NONE, 0)];
    return nil;
}

- (XVimEvaluator*)g:(XVimWindow*)window {
	return [[XVimGVisualEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"g"] parent:self];
}

- (XVimEvaluator*)i:(XVimWindow*)window {
	XVimOperatorAction *action = [[XVimSelectAction alloc] init];
	XVimEvaluator *evaluator = [[XVimTextObjectEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"i"] operatorAction:action withParent:self inclusive:NO];
	return evaluator;
}

- (XVimEvaluator*)J:(XVimWindow*)window {
	[[window sourceView] join:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)m:(XVimWindow*)window{
    // 'm{letter}' sets a local mark.
	return [[XVimMarkSetEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"m"]
												  parent:self];
}

- (XVimEvaluator*)p:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    XVimRegister* reg = [XVim instance].yankRegister;
    [view put:reg.string withType:reg.type afterCursor:YES count:[self numericArg]];
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
	XVimSourceView *view = [window sourceView];
    [view makeLowerCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	XVimSourceView *view = [window sourceView];
    [view makeUpperCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
	XVimSourceView *view = [window sourceView];
    if( view.selectionMode == MODE_CHARACTER ){
        return  [self ESC:window];
    }
    [view changeSelectionMode:MODE_CHARACTER];
    return self;
}

- (XVimEvaluator*)V:(XVimWindow*)window{
	XVimSourceView *view = [window sourceView];
    if( view.selectionMode == MODE_LINE){
        return  [self ESC:window];
    }
    [view changeSelectionMode:MODE_LINE];
    return self;
}

- (XVimEvaluator*)C_v:(XVimWindow*)window{
	XVimSourceView *view = [window sourceView];
    if( view.selectionMode == MODE_BLOCK){
        return  [self ESC:window];
    }
    [view changeSelectionMode:MODE_BLOCK];
    return self;
}

- (XVimEvaluator*)x:(XVimWindow*)window{
    return [self d:window];
}

- (XVimEvaluator*)X:(XVimWindow*)window{
    return [self D:window];
}

- (XVimEvaluator*)y:(XVimWindow*)window{
    [[window sourceView] yank:nil];
    return nil;
}

- (XVimEvaluator*)DQUOTE:(XVimWindow*)window{
    return [[XVimRegisterEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithArgument:@"\""] parent:self];
}

- (XVimEvaluator*)EQUAL:(XVimWindow*)window{
    [[window sourceView] filter:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    return nil;
}


- (XVimEvaluator*)ESC:(XVimWindow*)window{
    [[window sourceView] changeSelectionMode:MODE_VISUAL_NONE];
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
                               
							   //XVimSourceView *sourceView = [window sourceView];
                               [[window sourceView] changeSelectionMode:MODE_VISUAL_NONE];
                               return nil;
                           }
                                                                 onKeyPress:nil];
	
	return eval;
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
    [[window sourceView] shiftRight:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    return nil;
}


- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window{
    [[window sourceView] shiftLeft:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    return nil;
}

- (XVimEvaluator*)executeSearch:(XVimWindow*)window firstLetter:(NSString*)firstLetter 
{
    /*1
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
     */
    return [self ESC:window]; // Temprarily this feture is turned off
}

- (XVimEvaluator*)QUESTION:(XVimWindow*)window{
	return [self executeSearch:window firstLetter:@"?"];
}

- (XVimEvaluator*)SLASH:(XVimWindow*)window{
	return [self executeSearch:window firstLetter:@"/"];
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	XVimSourceView *view = [window sourceView];
    [view swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window {
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = to;
    [[window sourceView] move:m];
    return [self withNewContext];
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion inWindow:(XVimWindow*)window{
    [[window sourceView] move:motion];
    return self;
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