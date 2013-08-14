#import "NSTextStorage+VimOperation.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "DVTSourceTextViewHook.h"
#import "NSString+VimHelper.h"
#import "Logger.h"
#import "Utils.h"
#import "NSObject+ExtraData.h"

/*
 * XVimSourceView represent a text view used in XVim.
 * This is a layer above the actuall text view used in Xcode(DVTSourceTextView)
 * XVimSourceView keeps consistensy between VIM state and DVTSourceTextView.
 * All the evaluators(event handlers) send a request to XVimSourceView via XVimWindow
 * and complete its event.
 * So evaluators should NOT directly operate on DVTSourceTextView.
 */

/**
 * Main Idea of this class:
 * This class is a kind of "Model" class of Vim view.
 * So this class hold insertion point or selection area and so on.
 * To operate on view you first modify the values (they are usually property of this class)
 * and call [self _syncState]
 * _syncState method applys all the changes to the values to underlaying view class (Which is usually NSTextView)
 * Do not operate on the underlaying view class directly like [view setSelectedRange:range].
 * In some operation you may want to use NSTextView's method to achive its task like deleting text which may use [_view delete:self].
 * In this case you have to call [self _syncStateFromView] to keep the values(properties) 
 * in this class valid after you call underlaying view's operation method.
 **/

/**
 * Rules to implement XVimSourceView class
 *  - use "_" prefixed name to define internal(private) method.
 *  - DO not call [self _syncState] from internal(private) method.
 *
 *  - Do not use "setSelectedRange" method to set cursor position
 *    Use 
 *       [self _moveCursor];
 *       [self _syncState];
 *    instead
 *  - Do not change _insertionPoint variable directly. Use [self _moveCursor: preserveColumn] instead.
 *  - Do not use [_view insertText:(NSString*)] method. Use [self insertText: line: column:] or [_view insertText: replacementRange:]
 **/

/**
 * Notes:
 *    EOF can not be selected.
 *    It means that
 *      - [_view setSelectedRange:NSMakeRange( indexOfEOF, 0 )]   is allowed
 *      - [_view setSelectedRange:NSMakeRange( indexOfEOF, 1 )]   is not allowed (cause exception)
 **/


/**
 * Developing Notes:
 *  - Currently block selection does not support selecting newlines.
 *    In vim it is possible to move cursor when block selection but XVim does not support it currently (I think its not really big problem though)
 **/
/*
#define LOG_STATE() TRACE_LOG(@"mode:%d length:%d cursor:%d ip:%d begin:%d line:%d column:%d preservedColumn:%d", \
                            _selectionMode,            \
                            [self string].length,       \
                            _cursorMode,               \
                            _insertionPoint,           \
                            _selectionBegin,           \
                            [self lineNumber:_insertionPoint],           \
                            [self columnNumber:_insertionPoint],           \
                            _preservedColumn )


@interface XVimSourceView() {
	__weak NSTextView *_view;
}
@property (strong) NSMutableString* lastYankedText;
@property TEXT_TYPE lastYankedType;

@end

@implementation XVimSourceView
@synthesize insertionPoint = _insertionPoint;
@synthesize selectionBegin = _selectionBegin;
@synthesize selectionMode = _selectionMode;
@synthesize preservedColumn = _preservedColumn;
@synthesize cursorMode = _cursorMode;
@synthesize lastYankedText = _lastYankedText;
@synthesize lastYankedType = _lastYankedType;
@synthesize delegate = _delegate;

- (id)initWithView:(NSTextView*)view {
	if (self = [super init]) {
		_view = (NSTextView*)view;
        _insertionPoint = [_view selectedRange].location + [_view selectedRange].length;
        _preservedColumn = [self columnNumber:_insertionPoint];
        _selectionMode = XVIM_VISUAL_NONE;
        _selectionBegin = NSNotFound;
        _cursorMode = CURSOR_MODE_COMMAND;
        _lastYankedText = [[NSMutableString alloc] init];
        _lastYankedType = TEXT_TYPE_CHARACTERS;
        self.delegate = nil;
	}
	return self;
}

- (void)dealloc{
    [super dealloc];
    [_lastYankedText release];
    self.delegate = nil;
}
 

////////////////
// Properties //
////////////////
- (NSTextView*)view {
	return _view;
}
    
- (NSString *)string {
	return [_view string];
}


- (XVimPosition)insertionPosition{
    return XVimMakePosition(self.insertionLine, self.insertionColumn);
}

- (XVimPosition)selectionBeginPosition{
    return XVimMakePosition([self lineNumber:_selectionBegin], [self columnNumber:_selectionBegin]);
}

- (NSUInteger)insertionColumn{
    return [self columnNumber:_insertionPoint];
}

- (NSUInteger)insertionLine{
    return [self lineNumber:_insertionPoint];
}

- (NSUInteger)lineNumber:(NSUInteger)index{
    return [self.view.textStorage lineNumber:index];
}

////////// Premitive Operations (DO NOT USE THESE CODE!)///////////
- (void)moveBack:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self prev:_insertionPoint count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:NO];
    _preservedColumn = [self columnNumber:_insertionPoint];
}

- (void)moveFoward:(NSUInteger)count option:(MOTION_OPTION)opt{
    XVimMotionInfo info;
    NSUInteger nextPos = [self next:_insertionPoint count:count option:opt info:&info];
    [self _moveCursor:nextPos preserveColumn:NO];
    _preservedColumn = [self columnNumber:_insertionPoint];
}

- (void)moveDown:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self nextLine:_insertionPoint column:_preservedColumn count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:YES];
}

- (void)moveUp:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self prevLine:_insertionPoint column:_preservedColumn count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:YES];
}

//- (void)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info;

- (void)moveWordsBackward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self wordsBackward:_insertionPoint count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:NO];
}

- (void)moveSentencesForward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self sentencesForward:_insertionPoint count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:NO];
}

- (void)moveSentencesBackward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self sentencesBackward:_insertionPoint count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:NO];
}

- (void)moveParagraphsForward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self paragraphsForward:_insertionPoint count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:NO];
}

- (void)moveParagraphsBackward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self paragraphsBackward:_insertionPoint count:count option:opt];
    [self _moveCursor:nextPos preserveColumn:NO];
}



- (void)upperCase{
    //[self upperCaseForRange:[self _currentSelection]];
}

- (void)lowerCase{
    //[self lowerCaseForRange:[self _currentSelection]];
}


- (void)upperCaseForRange:(NSRange)range {
}

- (void)lowerCaseForRange:(NSRange)range {
    NSString* s = [self string];
	[self insertText:[[s substringWithRange:range] lowercaseString] replacementRange:range];
}

//////////////////////////////
// Selection (Visual Mode)  //
//////////////////////////////



- (void)deleteText {
	[_view delete:self];
}

- (void)cutText {
	[_view cut:self];
}

- (void)copyText {
	[_view copy:self];
}

- (void)moveUp {
	[_view moveUp:self];
}

- (void)moveDown {
	[_view moveDown:self];
}


- (void)moveForwardAndModifySelection {
	[_view moveForwardAndModifySelection:self];
}

- (void)moveBackward {
    [self move:XVIM_MAKE_MOTION(MOTION_BACKWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)moveBackwardAndModifySelection {
	[_view moveBackwardAndModifySelection:self];
}
	 
- (void)moveToBeginningOfLine {
    [self move:XVIM_MAKE_MOTION(MOTION_BEGINNING_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)moveToEndOfLine {
    [self move:XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)deleteForward {
	[_view deleteForward:self];
}

- (void)insertText:(NSString*)text {
	[_view insertText:text];
}

- (void)insertText:(NSString*)text replacementRange:(NSRange)range {
	[_view insertText:text replacementRange:range];
}

- (void)insertNewline {
	[_view insertNewline:self];
}

- (void)undo {
	[[_view undoManager] undo];
    [self _syncStateFromView];
    [self changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)redo {
	[[_view undoManager] redo];
    [self _syncStateFromView];
    [self changeSelectionMode:XVIM_VISUAL_NONE];
}

- (NSColor*)insertionPointColor {
	return [_view insertionPointColor];
}

- (void)showFindIndicatorForRange:(NSRange)range {
	[_view showFindIndicatorForRange:range];
}

- (NSRange)selectedRange {
    LOG_STATE();
    return NSMakeRange(_insertionPoint, 0);
}
*/

/*
- (void)syncStateFromView{
    NSNumber* n = [self.view dataForName:@"rangeChanged"];

// Without if condition here it used to cause
// corruption of insertion point integrity between ours and NSTextView's.
// (See commit 65241b)
// But this prohibit sync state from NSTextView when it is insertion evaluator (Issue #416)
// Unexpectedly currently
//   if( n != nil && [n boolValue] ){
        [self _syncStateFromView];
        [self.view setBool:NO forName:@"rangeChanged"];
//   }
    
    n = [self.view dataForName:@"rangeChanged"];
}

// Obsolete
// This is here because only compatibility reason
- (void)setSelectedRange:(NSRange)range {
    [self _setSelectedRange:range];
    [self _syncStateFromView];
}


//////////////////////
// Internal Methods //
//////////////////////

@end

 */