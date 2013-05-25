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
#import "XVimGVisualEvaluator.h"
#import "XVimRegisterEvaluator.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimOptions.h"
#import "XVim.h"

static NSString* MODE_STRINGS[] = {@"", @"-- VISUAL --", @"-- VISUAL LINE --", @"-- VISUAL BLOCK --"};

@interface XVimVisualEvaluator(){
    BOOL _waitForArgument;
	NSRange _operationRange;
    VISUAL_MODE _mode;
}
@end

@implementation XVimVisualEvaluator 

- (id)initWithWindow:(XVimWindow *)window mode:(VISUAL_MODE)mode {
    return [self initWithWindow:window mode:mode withRange:NSMakeRange(NSNotFound,0)];
}

- (id)initWithWindow:(XVimWindow *)window mode:(VISUAL_MODE)mode withRange:(NSRange)range{
	if (self = [self initWithWindow:window]) {
        _waitForArgument = NO;
        _mode = mode;
		_operationRange = range;
	}
	return self;
}

- (NSString*)modeString {
	return MODE_STRINGS[_mode];
}

- (void)becameHandler{
    [super becameHandler];
    [self.sourceView changeSelectionMode:_mode];
}
    
- (void)didEndHandler{
    if( !_waitForArgument ){
        [super didEndHandler];
        [self.sourceView changeSelectionMode:MODE_VISUAL_NONE];
        [[[XVim instance] repeatRegister] setVisualMode:_mode withRange:_operationRange];
    }
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_VISUAL];
}

- (void)drawRect:(NSRect)rect{
    XVimSourceView* sourceView = [self sourceView];
	
	NSUInteger glyphIndex = [self.window insertionPoint];
	NSRect glyphRect = [sourceView boundingRectForGlyphIndex:glyphIndex];
	
	[[[sourceView insertionPointColor] colorWithAlphaComponent:0.5] set];
	NSRectFillUsingOperation(glyphRect, NSCompositeSourceOver);
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    XVimEvaluator *nextEvaluator = [super eval:keyStroke];
    /**
     * The folloing code is to draw insertion point when its visual mode.
     * Original NSTextView does not draw insertion point so we have to do it manually.
     **/
    [self.sourceView.view lockFocus];
    [self drawRect:[self.sourceView boundingRectForGlyphIndex:self.sourceView.insertionPoint]];
    [self.sourceView.view setNeedsDisplayInRect:[self.sourceView.view visibleRect] avoidAdditionalLayout:NO];
    [self.sourceView.view unlockFocus];
    
    return nextEvaluator;
}

- (XVimEvaluator*)a{
    // FIXME
	//XVimOperatorAction *action = [[XVimSelectAction alloc] init];
    [self.argumentString appendString:@"a"];
	XVimEvaluator *evaluator = [[[XVimTextObjectEvaluator alloc] initWithWindow:self.window inner:NO] autorelease];
	return evaluator;
}

- (XVimEvaluator*)c{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    [[self sourceView] change:m];
    return [[[XVimInsertEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)C_b{
    [[self sourceView] scrollPageBackward:[self numericArg]];
    return self;
}

- (XVimEvaluator*)C_d{
    [[self sourceView] scrollHalfPageForward:[self numericArg]];
    return self;
}

- (XVimEvaluator*)d{
    [[self sourceView] delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
    return nil;
}

- (XVimEvaluator*)D{
    [[self sourceView] delete:XVIM_MAKE_MOTION(MOTION_NONE, LINEWISE, MOTION_OPTION_NONE, 0)];
    return nil;
}

- (XVimEvaluator*)C_f{
    [[self sourceView] scrollPageForward:[self numericArg]];
    return self;
}

- (XVimEvaluator*)g{
    [self.argumentString appendString:@"g"];
	return [[[XVimGVisualEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)i{
    // FIXME
	//XVimOperatorAction *action = [[XVimSelectAction alloc] init];
    [self.argumentString appendString:@"i"];
	XVimEvaluator *evaluator = [[[XVimTextObjectEvaluator alloc] initWithWindow:self.window inner:YES] autorelease];
	return evaluator;
}

- (XVimEvaluator*)J{
	[[self sourceView] join:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)m{
    // 'm{letter}' sets a local mark.
    [self.argumentString appendString:@"m"];
	return [[[XVimMarkSetEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)p{
    XVimSourceView* view = [self sourceView];
    XVimRegister* reg = self.yankRegister;
    [view put:reg.string withType:reg.type afterCursor:YES count:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)P{
    // Looks P works as p in Visual Mode.. right?
    return [self p];
}

- (XVimEvaluator*)s{
	// As far as I can tell this is equivalent to change
	return [self c];
}


- (XVimEvaluator*)u{
	XVimSourceView *view = [self sourceView];
    [view makeLowerCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)U{
	XVimSourceView *view = [self sourceView];
    [view makeUpperCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)C_u{
    [[self sourceView] scrollHalfPageBackward:[self numericArg]];
    return self;
}

- (XVimEvaluator*)v{
	XVimSourceView *view = [self sourceView];
    if( view.selectionMode == MODE_CHARACTER ){
        return  [self ESC];
    }
    [view changeSelectionMode:MODE_CHARACTER];
    return self;
}

- (XVimEvaluator*)V{
	XVimSourceView *view = [self sourceView];
    if( view.selectionMode == MODE_LINE){
        return  [self ESC];
    }
    [view changeSelectionMode:MODE_LINE];
    return self;
}

- (XVimEvaluator*)C_v{
	XVimSourceView *view = [self sourceView];
    if( view.selectionMode == MODE_BLOCK){
        return  [self ESC];
    }
    [view changeSelectionMode:MODE_BLOCK];
    return self;
}

- (XVimEvaluator*)x{
    return [self d];
}

- (XVimEvaluator*)X{
    return [self D];
}

- (XVimEvaluator*)y{
    [[self sourceView] yank:nil];
    return nil;
}

- (XVimEvaluator*)DQUOTE{
    [self.argumentString appendString:@"\""];
    self.onChildCompleteHandler = @selector(onComplete_DQUOTE:);
    _waitForArgument = YES;
    return  [[[XVimRegisterEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_DQUOTE:(XVimRegisterEvaluator*)childEvaluator{
    XVimRegister *xregister = childEvaluator.reg;
    if (xregister.isReadOnly == NO || [xregister.displayName isEqualToString:@"%"] ){
        self.yankRegister = xregister;
        [self.argumentString appendString:xregister.displayName];
        self.onChildCompleteHandler = @selector(onChildComplete:);
    }
    _waitForArgument = YES;
    return self;
}

- (XVimEvaluator*)Y{
    //TODO: support yunk linewise
    [[self sourceView] yank:nil];
    return nil;
}

/*
TODO: This block is from commit 42498.
      This is not merged. This is about percent register
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
*/

- (XVimEvaluator*)EQUAL{
    [[self sourceView] filter:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    return nil;
}

- (XVimEvaluator*)ESC{
    [[self sourceView] changeSelectionMode:MODE_VISUAL_NONE];
    return nil;
}

- (XVimEvaluator*)C_c{
    return [self ESC];
}

- (XVimEvaluator*)C_LSQUAREBRACKET{
    return [self ESC];
}

- (XVimEvaluator*)COLON{
	XVimEvaluator *eval = [[XVimCommandLineEvaluator alloc] initWithWindow:self.window
                                                                firstLetter:@":'<,'>"
                                                                    history:[[XVim instance] exCommandHistory]
                                                                 completion:^ XVimEvaluator* (NSString* command) 
                           {
                               XVimExCommand *excmd = [[XVim instance] excmd];
                               [excmd executeCommand:command inWindow:self.window];
                               
							   //XVimSourceView *sourceView = [window sourceView];
                               [[self sourceView] changeSelectionMode:MODE_VISUAL_NONE];
                               return nil;
                           }
                                                                 onKeyPress:nil];
	
	return eval;
}

- (XVimEvaluator*)GREATERTHAN{
    [[self sourceView] shiftRight:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    return nil;
}


- (XVimEvaluator*)LESSTHAN{
    [[self sourceView] shiftLeft:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    return nil;
}

- (XVimEvaluator*)executeSearch:(XVimWindow*)window firstLetter:(NSString*)firstLetter {
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
    return [self ESC]; // Temprarily this feture is turned off
}

- (XVimEvaluator*)QUESTION{
	return [self executeSearch:self.window firstLetter:@"?"];
}

- (XVimEvaluator*)SLASH{
	return [self executeSearch:self.window firstLetter:@"/"];
}

- (XVimEvaluator*)TILDE{
	XVimSourceView *view = [self sourceView];
    [view swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
	return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = to;
    [[self sourceView] move:m];
    return self;
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    [[self sourceView] move:motion];
    [self resetNumericArg];
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
