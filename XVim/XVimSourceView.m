#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "DVTSourceTextViewHook.h"
#import "NSString+VimHelper.h"
#import "Logger.h"

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

- (void)_deleteLine:(NSUInteger)lineNum;
- (void)_setSelectedRange:(NSRange)range;
- (void)_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (NSUInteger)_getPositionFrom:(NSUInteger)current Motion:(XVimMotion*)motion;
- (void)_syncStateFromView; // update our instance variables with _view's properties
- (void)_syncState; // update _view's properties with our variables
- (NSArray*)_selectedRanges;
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
        _selectionMode = MODE_VISUAL_NONE;
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

- (NSUInteger)realLength{
    DVTFoldingTextStorage* storage = [(DVTSourceTextView*)_view textStorage];
    DVTTextStorage* real = storage.realStorage;
    return real.length;
}

- (NSArray*)selectedRanges{
    return [self _selectedRanges];
}

- (NSUInteger)insertionColumn{
    return [self columnNumber:_insertionPoint];
}

- (NSUInteger)insertionLine{
    return [self lineNumber:_insertionPoint];
}

- (NSArray*)_selectedRanges{
    NSUInteger selectionStart, selectionEnd = NSNotFound;
    NSMutableArray* rangeArray = [[[NSMutableArray alloc] init] autorelease];
    // And then select new selection area
    if (_selectionMode == MODE_VISUAL_NONE) { // its not in selecting mode
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(_insertionPoint,0)]];
    }
    else if( _selectionMode == MODE_CHARACTER){
        selectionStart = MIN(_insertionPoint,_selectionBegin);
        selectionEnd = MAX(_insertionPoint,_selectionBegin);
        if( [self isEOF:selectionStart] ){
            // EOF can not be selected
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,0)]];
        }else if( [self isEOF:selectionEnd] ){
            selectionEnd--;
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }else{
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }
    }else if(_selectionMode == MODE_LINE ){
        NSUInteger min = MIN(_insertionPoint,_selectionBegin);
        NSUInteger max = MAX(_insertionPoint,_selectionBegin);
        selectionStart = [self firstOfLine:min];
        selectionEnd   = [self tailOfLine:max];
        if( [self isEOF:selectionStart] ){
            // EOF can not be selected
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,0)]];
        }else if( [self isEOF:selectionEnd] ){
            selectionEnd--;
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }else{
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }
    }else if( _selectionMode == MODE_BLOCK){
        // Define the block as a rect by line and column number
        NSUInteger top    = MIN( [self lineNumber:_insertionPoint], [self lineNumber:_selectionBegin] );
        NSUInteger bottom = MAX( [self lineNumber:_insertionPoint], [self lineNumber:_selectionBegin] );
        NSUInteger left   = MIN( [self columnNumber:_insertionPoint], [self columnNumber:_selectionBegin] );
        NSUInteger right  = MAX( [self columnNumber:_insertionPoint], [self columnNumber:_selectionBegin] );
        for( NSUInteger i = 0; i < bottom-top+1 ; i++ ){
            selectionStart = [self positionAtLineNumber:top+i column:left];
            selectionEnd = [self positionAtLineNumber:top+i column:right];
            if( [self isEOF:selectionStart] || [self isTOL:selectionStart]){
                // EOF or EOL can not be selected
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,0)]]; // 0 means No selection. This information is important and used in operators like 'delete'
            }else if( [self isEOF:selectionEnd] || [self isTOL:selectionEnd]){
                selectionEnd--;
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
            }else{
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
            }
        }
    }
    return rangeArray;
}

//////////////////
// Operations   //
//////////////////

////////// Top level operation interface/////////

- (void)escapeFromInsert{
    [self _syncStateFromView];
    _cursorMode = CURSOR_MODE_COMMAND;
    if(![self isFirstOfLine:_insertionPoint]){
        [self _moveCursor:_insertionPoint-1 preserveColumn:NO];
    }
    [self _syncState];
}

- (void)move:(XVimMotion*)motion{
    METHOD_TRACE_LOG();
    NSUInteger next = [self _getPositionFrom:_insertionPoint Motion:motion];
    if( next == NSNotFound ){
        return;
    }
    switch( motion.motion ){
        case MOTION_LINE_BACKWARD:
        case MOTION_LINE_FORWARD:
            // TODO: Preserve column option can be included in motion object
            [self _moveCursor:next preserveColumn:YES];
            break;
        default:
            [self _moveCursor:next preserveColumn:NO];
            break;
    }
    
    [self _syncState];
}

- (void)_yankRanges:(NSArray*)ranges withType:(MOTION_TYPE)type{
    if( _selectionMode == MODE_VISUAL_NONE ){
        if( type == CHARACTERWISE_EXCLUSIVE || type == CHARACTERWISE_INCLUSIVE ){
            _lastYankedType = TEXT_TYPE_CHARACTERS;
        }else if( type == LINEWISE ){
            _lastYankedType = TEXT_TYPE_LINES;
        }
    }else if( _selectionMode == MODE_CHARACTER){
        _lastYankedType = TEXT_TYPE_CHARACTERS;
    }else if( _selectionMode == MODE_LINE ){
        _lastYankedType = TEXT_TYPE_LINES;
    }else if( _selectionMode == MODE_BLOCK ){
        _lastYankedType = TEXT_TYPE_BLOCK;
    }
    TRACE_LOG(@"YANKED TYPE:%d", _lastYankedType);
    
    NSMutableArray* tmp = [[[NSMutableArray alloc] init] autorelease];
    for( NSValue* range in ranges ){
        if( range.rangeValue.length == 0 ){
            // Nothing to yank
            [tmp addObject:@""];
        }else{
            NSString* str = [[_view string] substringWithRange:range.rangeValue];
            [tmp addObject:str];
        }
    }
    
    // LINEWISE yank of last line (the line including EOF) is special case
    // where we treat EOF as a newline when yank
    if( _lastYankedType == TEXT_TYPE_LINES){
        NSString* lastLine = [tmp lastObject];
        if( !isNewLine([lastLine characterAtIndex:[lastLine length]-1]) ){
            [tmp addObject:@""]; // add empty dummy line
        }
    }
   [_lastYankedText setString:[tmp componentsJoinedByString:@"\n"]];
    TRACE_LOG(@"YANKED STRING : %@", _lastYankedText);
}

- (void)delete:(XVimMotion*)motion{
    NSAssert( !(_selectionMode == MODE_VISUAL_NONE && motion == nil), @"motion must be specified if current selection mode is not visual");
    if( _insertionPoint == 0 && [[self string] length] == 0 ){
        return ;
    }
    
    motion.info->deleteLastLine = NO;
    if( _selectionMode == MODE_VISUAL_NONE ){
        NSRange r;
        NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
        if( to == NSNotFound ){
            return;
        }
        // We have to treat some special cases
        // When a cursor get end of line with "l" motion, make the motion type to inclusive.
        // This make you to delete the last character. (if its exclusive last character never deleted with "dl")
        if( motion.motion == MOTION_FORWARD && motion.info->reachedEndOfLine){
            motion.type = CHARACTERWISE_INCLUSIVE;
        }
        if( motion.motion == MOTION_WORD_FORWARD ){
            if (motion.info->isFirstWordInALine && motion.info->lastEndOfLine != NSNotFound) {
                // Special cases for word move over a line break.
                to = motion.info->lastEndOfLine;
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
        }
        r = [self getOperationRangeFrom:_insertionPoint To:to Type:motion.type];
        if( motion.type == LINEWISE && [self isLastLine:to]){
            if( r.location != 0 ){
                motion.info->deleteLastLine = YES;
                r.location--;
                r.length++;
            }
        }
        [self _yankRanges:[NSArray arrayWithObject:[NSValue valueWithRange:r]] withType:motion.type];
        [self _setSelectedRange:r];
    }else{
        // Currently not supportin deleting EOF with selection mode.
        // This is because of the fact that NSTextView does not allow select EOF
        [self _yankRanges:[self _selectedRanges] withType:motion.type];
    }
    
    [_view delete:self];
    if( _delegate != nil ){
        [_delegate textDeleted:_lastYankedText  withType:_lastYankedType inView:self];
    }
    
    [self _moveCursor:_insertionPoint preserveColumn:NO];
    [self _syncStateFromView];
    [self changeSelectionMode:MODE_VISUAL_NONE];
}

- (void)change:(XVimMotion*)motion{
    BOOL insertNewline = NO;
    if( motion.type == LINEWISE || _selectionMode == MODE_LINE){
        // 'cc' deletes the lines but need to keep the last newline.
        // So insertNewline as 'O' does before entering insert mode
        insertNewline = YES;
    }
    NSUInteger insertionPointAfterDelete = _insertionPoint;
    if( _selectionMode != MODE_VISUAL_NONE ){
        insertionPointAfterDelete = [[[self _selectedRanges] objectAtIndex:0] rangeValue].location;
    }
    // "cw" is like "ce" if the cursor is on a word ( in this case blank line is not treated as a word )
    if( motion.motion == MOTION_WORD_FORWARD && [self isNonBlank:_insertionPoint] ){
        motion.motion = MOTION_END_OF_WORD_FORWARD;
        motion.type = CHARACTERWISE_INCLUSIVE;
    }
    [self delete:motion];
    _cursorMode = CURSOR_MODE_INSERT;
    if( motion.info->deleteLastLine){
        [self insertNewlineBelowLine:[self lineNumber:_insertionPoint]];
    }
    else if( insertNewline ){
        [self insertNewlineAboveLine:[self lineNumber:_insertionPoint]];
    }else{
        [self _moveCursor:insertionPointAfterDelete preserveColumn:NO];
    }
    [self changeSelectionMode:MODE_VISUAL_NONE];
    [self _syncState];
}

- (void)yank:(XVimMotion*)motion{
    NSAssert( !(_selectionMode == MODE_VISUAL_NONE && motion == nil), @"motion must be specified if current selection mode is not visual");
    NSUInteger insertionPointAfterYank = _insertionPoint;
    if( _selectionMode == MODE_VISUAL_NONE ){
        NSRange r;
        NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
        if( NSNotFound == to ){
            return;
        }
        r = [self getOperationRangeFrom:_insertionPoint To:to Type:motion.type];
        BOOL eof = [self isEOF:to];
        BOOL blank = [self isBlankLine:to];
        if( motion.type == LINEWISE && blank && eof){
            if( r.location != 0 ){
                r.location--;
                r.length++;
            }
        }
        [self _yankRanges:[NSArray arrayWithObject:[NSValue valueWithRange:r]] withType:motion.type];
    }else{
        [self _yankRanges:[self _selectedRanges] withType:motion.type];
    }
    
    if( _delegate != nil ){
        [_delegate textYanked:_lastYankedText  withType:_lastYankedType inView:self];
    }
    
    [self _moveCursor:insertionPointAfterYank preserveColumn:NO];
    [self _syncStateFromView];
    [self changeSelectionMode:MODE_VISUAL_NONE];
}

- (void)put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count{
    if( _selectionMode != MODE_VISUAL_NONE ){
        [self delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 1)];
        after = NO;
    }
    
    NSUInteger insertionPointAfterPut = _insertionPoint;
    NSUInteger targetPos = _insertionPoint;
    if( type == TEXT_TYPE_CHARACTERS ){
        //Forward insertion point +1 if after flag if on
        if (![self isNewLine:_insertionPoint] && after) {
            targetPos++;
        }
        insertionPointAfterPut = targetPos;
        [self _setSelectedRange:NSMakeRange(targetPos,0)];
        for(NSUInteger i = 0; i < count ; i++ ){
            [_view insertText:text];
        }
    }else if( type == TEXT_TYPE_LINES ){
        if( after ){
            [self insertNewlineBelow];
            targetPos = _insertionPoint;
        }else{
            targetPos= [self firstOfLine:_insertionPoint];
        }
        insertionPointAfterPut = _insertionPoint;
        [self _setSelectedRange:NSMakeRange(targetPos,0)];
        for(NSUInteger i = 0; i < count ; i++ ){
            if( after && i == count-1 ){
                // delete newline at the end. (TEXT_TYPE_LINES always have newline at the end of the text)
                NSString* t = [text  substringToIndex:text.length-1];
                [_view insertText:t];
            } else{
                [_view insertText:text];
            } }
    }else if( type == TEXT_TYPE_BLOCK ){
        //Forward insertion point +1 if after flag if on
        if (![self isNewLine:_insertionPoint] && ![self isEOF:_insertionPoint] && after) {
            _insertionPoint++;
        }
        insertionPointAfterPut = _insertionPoint;
        NSUInteger insertPos = _insertionPoint;
        NSUInteger column = [self columnNumber:insertPos];
        NSUInteger startLine = [self lineNumber:insertPos];
        NSArray* lines = [text componentsSeparatedByString:@"\n"];
        for( NSUInteger i = 0 ; i < lines.count ; i++){
            NSString* line = [lines objectAtIndex:i];
            NSUInteger targetLine = startLine + i;
            NSUInteger head = [self positionAtLineNumber:targetLine];
            if( NSNotFound == head ){
                NSAssert( targetLine != 0, @"This should not be happen");
                [self insertNewlineBelowLine:targetLine-1];
                head = [self positionAtLineNumber:targetLine];
            }
            NSAssert( NSNotFound != head , @"Head of the target line must be found at this point");
            
            // Find next insertion point
            NSUInteger max = [self maxColumnAtLineNumber:[self lineNumber:head]];
            NSAssert( max != NSNotFound , @"Should not be NSNotFound");
            if( column > max ){
                // If the line does not have enough column pad it with spaces
                NSUInteger spaces = column - max;
                NSUInteger end = [self tailOfLine:head];
                for( NSUInteger i = 0 ; i < spaces; i++){
                    [_view insertText:@" " replacementRange:NSMakeRange(end,0)];
                }
            }
            for(NSUInteger i = 0; i < count ; i++ ){
                [self insertText:line line:targetLine column:column];
            }
        }
    }
    
    
    [self _moveCursor:insertionPointAfterPut preserveColumn:NO];
    [self _syncState];
    [self changeSelectionMode:MODE_VISUAL_NONE];
}

- (void)swapCase:(XVimMotion*)motion{
    if( _insertionPoint == 0 && [[self string] length] == 0 ){
        return ;
    }
    
    if( _selectionMode == MODE_VISUAL_NONE ){
        if( motion.motion == MOTION_NONE ){
            XVimMotion* m = XVIM_MAKE_MOTION(MOTION_FORWARD,CHARACTERWISE_EXCLUSIVE,LEFT_RIGHT_NOWRAP,motion.count);
            NSUInteger end = [self _getPositionFrom:_insertionPoint Motion:m];
            if( end == NSNotFound){
                return;
            }
            if( m.info->reachedEndOfLine ){
                [self toggleCaseForRange:[self getOperationRangeFrom:_insertionPoint To:end Type:CHARACTERWISE_INCLUSIVE]];
            }else{
                [self toggleCaseForRange:[self getOperationRangeFrom:_insertionPoint To:end Type:CHARACTERWISE_EXCLUSIVE]];
            }
            [self _moveCursor:end preserveColumn:NO];
        }else{
            NSRange r;
            NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
            if( to == NSNotFound){
                return;
            }
            r = [self getOperationRangeFrom:_insertionPoint To:to Type:motion.type];
            [self toggleCaseForRange:r];
            [self _moveCursor:r.location preserveColumn:NO];
        }
    }else{
        NSArray* ranges = [self _selectedRanges];
        for( NSValue* val in ranges){
            [self toggleCaseForRange:[val rangeValue]];
        }
        [self _moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self _syncState];
    [self changeSelectionMode:MODE_VISUAL_NONE];
    
}

- (void)makeLowerCase:(XVimMotion*)motion{
    if( _insertionPoint == 0 && [[self string] length] == 0 ){
        return ;
    }
    
    NSString* s = [self string];
    if( _selectionMode == MODE_VISUAL_NONE ){
        NSRange r;
        NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
        if( to == NSNotFound ){
            return;
        }
        r = [self getOperationRangeFrom:_insertionPoint To:to Type:motion.type];
        [self insertText:[[s substringWithRange:r] lowercaseString] replacementRange:r];
        [self _moveCursor:r.location preserveColumn:NO];
    }else{
        NSArray* ranges = [self _selectedRanges];
        for( NSValue* val in ranges){
            [self insertText:[[s substringWithRange:val.rangeValue] lowercaseString] replacementRange:val.rangeValue];
        }
        [self _moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self _syncState];
    [self changeSelectionMode:MODE_VISUAL_NONE];
}

- (void)makeUpperCase:(XVimMotion*)motion{
    if( _insertionPoint == 0 && [[self string] length] == 0 ){
        return ;
    }
    
    NSString* s = [self string];
    if( _selectionMode == MODE_VISUAL_NONE ){
        NSRange r;
        NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
        if( to == NSNotFound ){
            return;
        }
        r = [self getOperationRangeFrom:_insertionPoint To:to Type:motion.type];
        [self insertText:[[s substringWithRange:r] uppercaseString] replacementRange:r];
        [self _moveCursor:r.location preserveColumn:NO];
    }else{
        NSArray* ranges = [self _selectedRanges];
        for( NSValue* val in ranges){
           [self insertText:[[s substringWithRange:val.rangeValue] uppercaseString] replacementRange:val.rangeValue];
        }
        [self _moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self _syncState];
    [self changeSelectionMode:MODE_VISUAL_NONE];
    
}

- (void)joinAtLineNumber:(NSUInteger)line{
    BOOL needSpace = NO;
    NSUInteger headOfLine = [self positionAtLineNumber:line];
    if( headOfLine == NSNotFound){
        return;
    }

    NSUInteger tail = [self tailOfLine:headOfLine];
    if( [self isEOF:tail] ){
        // This is the last line and nothing to join
        return;
    }
    
    // Check if we need to insert space between lines.
    NSUInteger endOfLine = [self endOfLine:headOfLine];
    if( endOfLine != NSNotFound ){
        // This is not blank line so we check if the last character is space or not .
        if( ![self isWhiteSpace:endOfLine] ){
            needSpace = YES;
        }
    }

    // Search in next line for the position to join(skip white spaces in next line)
    NSUInteger posToJoin = [self nextLine:headOfLine column:0 count:1 option:MOTION_OPTION_NONE];
    NSUInteger tmp = [self nextNonBlankInALine:posToJoin];
    if( NSNotFound == tmp ){
        // Only white spaces are found in the next line
        posToJoin = [self tailOfLine:posToJoin];
    }else{
        posToJoin = tmp;
    }
    if( ![self isEOF:posToJoin] && [self.string characterAtIndex:posToJoin] == ')' ){
        needSpace = NO;
    }
    
    // delete "tail" to "posToJoin" excluding the position of "posToJoin" and insert space if need.
    if( needSpace ){
        [_view insertText:@" " replacementRange:NSMakeRange(tail, posToJoin-tail)];
    }else{
        [_view insertText:@""  replacementRange:NSMakeRange(tail, posToJoin-tail)];
    }

}

- (void)join:(NSUInteger)count{
    NSUInteger start = [[[self _selectedRanges] objectAtIndex:0] rangeValue].location;
    if( _selectionMode != MODE_VISUAL_NONE ){
        // If in selection mode ignore count
        NSRange lastSelection = [[[self _selectedRanges] lastObject] rangeValue];
        NSUInteger end = lastSelection.location + lastSelection.length - 1;
        NSUInteger lineBegin = [self lineNumber:start];
        NSUInteger lineEnd = [self lineNumber:end];
        count = lineEnd - lineBegin ;
    }
    
    for( NSUInteger i = 0; i < count ; i++ ){
        [self joinAtLineNumber:[self lineNumber:start]];
    }
    
    [self _syncStateFromView];
    [self changeSelectionMode:MODE_VISUAL_NONE];
    return;
}

- (void)filter:(XVimMotion*)motion{
    if( _insertionPoint == 0 && [[self string] length] == 0 ){
        return ;
    }
    
    NSUInteger insertionAfterFilter = _insertionPoint;
    NSRange filterRange;
    if( _selectionMode == MODE_VISUAL_NONE ){
        NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
        if( to == NSNotFound ){
            return;
        }
        filterRange = [self getOperationRangeFrom:_insertionPoint To:to Type:LINEWISE];
    }else{
        insertionAfterFilter = [[[self _selectedRanges] lastObject] rangeValue].location;
        NSUInteger start = [[[self _selectedRanges] objectAtIndex:0] rangeValue].location;
        NSRange lastSelection = [[[self _selectedRanges] lastObject] rangeValue];
        NSUInteger end = lastSelection.location + lastSelection.length - 1;
        filterRange  = NSMakeRange(start, end-start+1);
    }
    
	[self indentCharacterRange: filterRange];
    [self _syncStateFromView];
    [self _moveCursor:insertionAfterFilter preserveColumn:NO];
    [self changeSelectionMode:MODE_VISUAL_NONE];
}

- (void)shift:(XVimMotion*)motion right:(BOOL)right{
    if( _insertionPoint == 0 && [[self string] length] == 0 ){
        return ;
    }
    
    NSUInteger count = 1;
    NSUInteger insertionAfterShift = _insertionPoint;
    if( _selectionMode == MODE_VISUAL_NONE ){
        NSUInteger to = [self _getPositionFrom:_insertionPoint Motion:motion];
        if( to == NSNotFound ){
            return;
        }
        NSRange r = [self getOperationRangeFrom:_insertionPoint To:to Type:LINEWISE];
        insertionAfterShift = r.location;
        [self _setSelectedRange:r];
    }else{
        count = motion.count; // Only when its visual mode we treat caunt as repeating shifting
        insertionAfterShift = [[[self _selectedRanges] lastObject] rangeValue].location;
        NSUInteger start = [[[self _selectedRanges] objectAtIndex:0] rangeValue].location;
        NSRange lastSelection = [[[self _selectedRanges] lastObject] rangeValue];
        NSUInteger end = lastSelection.location + lastSelection.length - 1;
        [self _setSelectedRange:NSMakeRange(start, end-start+1)];
    }
    
    for( NSUInteger i = 0 ; i < count ; i++ ){
        if( right ){
            [(DVTSourceTextView*)_view shiftRight:self];
        }else{
            [(DVTSourceTextView*)_view shiftLeft:self];
        }
    }
	NSUInteger cursorLocation = [self firstNonBlankInALine:insertionAfterShift];
    [self _moveCursor:cursorLocation preserveColumn:NO];
    [self changeSelectionMode:MODE_VISUAL_NONE];
    [self _syncState];
    
    
}

- (void)shiftRight:(XVimMotion*)motion{
    [self shift:motion right:YES];
}

- (void)shiftLeft:(XVimMotion*)motion{
    [self shift:motion right:NO];
}

- (void)insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column{
    NSUInteger pos = [self positionAtLineNumber:line column:column];
    if( pos == NSNotFound ){
        return;
    }
    [_view insertText:str replacementRange:NSMakeRange(pos,0)];
}

- (void)insertNewlineBelowLine:(NSUInteger)line{
    NSAssert( line != 0, @"line number starts from 1");
    NSUInteger pos = [self positionAtLineNumber:line];
    if( NSNotFound == pos ){
        return;
    }
    pos = [self tailOfLine:pos];
    [_view insertText:@"\n" replacementRange:NSMakeRange(pos ,0)];
    [self _moveCursor:pos+1 preserveColumn:NO];
    [self _syncState];
}

- (void)insertNewlineBelow{
    NSUInteger l = _insertionPoint;
    // TODO: Use _insertionPoint to move cursor
    NSUInteger tail = [self tailOfLine:l];
    [[self view] setSelectedRange:NSMakeRange(tail,0)];
    [[self view] insertNewline:self];
    [self _syncStateFromView];
}

- (void)insertNewlineAboveLine:(NSUInteger)line{
    NSAssert( line != 0, @"line number starts from 1");
    NSUInteger pos = [self positionAtLineNumber:line];
    if( NSNotFound == pos ){
        return;
    }
    if( 1 != line ){
        [self insertNewlineBelowLine:line-1];
    }else{
        [_view insertText:@"\n" replacementRange:NSMakeRange(0,0)];
    }
}

- (void)insertNewlineAbove{
    NSUInteger l = _insertionPoint;
    NSUInteger head = [self headOfLine:l];
    if( NSNotFound == head ){
        head = l;
    }
    if( 0 != head ){
        // TODO: Use _insertionPoint to move cursor
        [[self view] setSelectedRange:NSMakeRange(head-1,0)];
        [[self view] insertNewline:self];
    }else{
        // TODO: Use _insertionPoint to move cursor
        [[self view] setSelectedRange:NSMakeRange(head,0)];
        [[self view] insertNewline:self];
        [[self view] setSelectedRange:NSMakeRange(0,0)];
    }
    
    [self _syncStateFromView];
}

- (void)append{
    NSAssert(_cursorMode == CURSOR_MODE_COMMAND, @"_cursorMode shoud be CURSOR_MODE_COMMAND");
    _cursorMode = CURSOR_MODE_INSERT;
    if( ![self isEOF:_insertionPoint] && ![self isNewLine:_insertionPoint]){
        _insertionPoint++;
    }
    [self insert];
}

- (void)insert{
    _cursorMode = CURSOR_MODE_INSERT;
    [self _syncState];
}

- (void)appendAtEndOfLine{
    _cursorMode = CURSOR_MODE_INSERT;
    [self changeSelectionMode:MODE_VISUAL_NONE];
    [self _moveCursor:[self tailOfLine:_insertionPoint] preserveColumn:NO];
    [self _syncState];
    
}

- (void)insertBeforeFirstNonBlank{
    _insertionPoint = [self firstNonBlankInALine:_insertionPoint];
    [self insert];
}

- (void)passThroughKeyDown:(NSEvent*)event{
    [(DVTSourceTextView*)_view keyDown_:event];
    [self _syncStateFromView];
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


// Scrolls
- (void)scrollPageForward:(NSUInteger)count{
    [self pageForward:_insertionPoint count:count];
}

- (void)scrollPageBackward:(NSUInteger)count{
    [self pageBackward:_insertionPoint count:count];
}

- (void)scrollHalfPageForward:(NSUInteger)count{
    [self halfPageForward:_insertionPoint count:count];
}

- (void)scrollHalfPageBackward:(NSUInteger)count{
    [self halfPageBackward:_insertionPoint count:count];
}

- (void)scrollLineForward:(NSUInteger)count{
    [self lineDown:_insertionPoint count:count];
}

- (void)scrollLineBackward:(NSUInteger)count{
    [self lineUp:_insertionPoint count:count];
}

- (void)upperCase{
    //[self upperCaseForRange:[self _currentSelection]];
}

- (void)lowerCase{
    //[self lowerCaseForRange:[self _currentSelection]];
}

- (void)toggleCaseForRange:(NSRange)range {
    NSString* text = [self string];
	
	NSMutableString *substring = [[text substringWithRange:range] mutableCopy];
	for (NSUInteger i = 0; i < range.length; ++i) {
		NSRange currentRange = NSMakeRange(i, 1);
		NSString *currentCase = [substring substringWithRange:currentRange];
		NSString *upperCase = [currentCase uppercaseString];
		
		NSRange replaceRange = NSMakeRange(i, 1);
		if ([currentCase isEqualToString:upperCase]){
			[substring replaceCharactersInRange:replaceRange withString:[currentCase lowercaseString]];
		}else{
			[substring replaceCharactersInRange:replaceRange withString:upperCase];
		}	
	}
	
	[self insertText:substring replacementRange:range];
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

- (void)changeSelectionMode:(VISUAL_MODE)mode{
    if( _selectionMode == MODE_VISUAL_NONE && mode != MODE_VISUAL_NONE ){
        _selectionBegin = _insertionPoint;
    }else if( _selectionMode != MODE_VISUAL_NONE && mode == MODE_VISUAL_NONE){
        _selectionBegin = NSNotFound;
    }
    _selectionMode = mode;
    [self _syncState];
    return;
}

// Scrolling  //
////////////////
#define XVimAddPoint(a,b) NSMakePoint(a.x+b.x,a.y+b.y)  // Is there such macro in Cocoa?
#define XVimSubPoint(a,b) NSMakePoint(a.x-b.x,a.y-b.y)  // Is there such macro in Cocoa?

- (NSUInteger)lineUp:(NSUInteger)index count:(NSUInteger)count { // C-y
  [_view scrollLineUp:self];
  NSRect visibleRect = [[_view enclosingScrollView] contentView].bounds;
  NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:[_view textContainer]];
  NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
  if (relativeInsertionPoint.y > visibleRect.size.height) {
    [_view moveUp:self];
    NSPoint newPoint = [[_view layoutManager] boundingRectForGlyphRange:[_view selectedRange] inTextContainer:[_view textContainer]].origin;
    index = [self glyphIndexForPoint:newPoint];
  }
  return index;
}

- (NSUInteger)lineDown:(NSUInteger)index count:(NSUInteger)count { // C-e
  [_view scrollLineDown:self];
  NSRect visibleRect = [[_view enclosingScrollView] contentView].bounds;
  NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:[_view textContainer]];
  if (currentInsertionRect.origin.y < visibleRect.origin.y) {
    [_view moveDown:self];
    NSPoint newPoint = NSMakePoint(currentInsertionRect.origin.x, visibleRect.origin.y);
    index = [self glyphIndexForPoint:newPoint];
  }
  return index;
}

- (void)scroll:(CGFloat)ratio count:(NSUInteger)count{
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat scrollSize = visibleRect.size.height * ratio * count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize ); // This may be beyond the beginning or end of document (intentionally)
    
    // Cursor position relative to left-top origin shold be kept after scroll ( Exception is when it scrolls beyond the beginning or end of document)
    NSRect currentInsertionRect = [self boundingRectForGlyphIndex:_insertionPoint];
    NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
    //TRACE_LOG(@"Rect:%f %f    realIndex:%d   foldedIndex:%d", currentInsertionRect.origin.x, currentInsertionRect.origin.y, _insertionPoint, index);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = XVimAddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    // TODO: consider blank-EOF line. Xcode does not return blank-EOF index with following method...
    NSUInteger cursorIndexAfterScroll= [self glyphIndexForPoint:cursorAfterScroll];
    
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [self boundingRectForGlyphIndex:cursorIndexAfterScroll];
    NSPoint relativeInsertionPointAfterScroll = XVimSubPoint(insertionRectAfterScroll.origin, scrollPoint);
    CGFloat heightDiff = relativeInsertionPointAfterScroll.y - relativeInsertionPoint.y;
    scrollPoint.y += heightDiff;
    // Prohibit scroll beyond the bounds of document
    if( scrollPoint.y > [[scrollView documentView] frame].size.height - visibleRect.size.height ){
        scrollPoint.y = [[scrollView documentView] frame].size.height - visibleRect.size.height ;
    } else if (scrollPoint.y < 0.0) {
      scrollPoint.y = 0.0;
    }
  
    [[scrollView contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
	
    cursorIndexAfterScroll = [self firstNonBlankInALine:cursorIndexAfterScroll];
    [self _moveCursor:cursorIndexAfterScroll preserveColumn:NO];
    [self _syncState];
    
}

- (NSUInteger)scrollBottom:(NSNumber*)count { // zb / z-
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = NSMakePoint(0.0f, NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f);
    bottom.y -= NSHeight([[scrollView contentView] bounds]);
    if( bottom.y < 0.0 ){
        bottom.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:bottom];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (NSUInteger)scrollCenter:(NSNumber*)count { // zz / z.
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint center = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    center.y -= NSHeight([[scrollView contentView] bounds]) / 2.0f;
    if( center.y < 0.0 ){
        center.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:center];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (NSUInteger)scrollTop:(NSNumber*)count { // zt / z<CR>
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (void)scrollTo:(NSUInteger)location {
    // Update: I do not know if we really need Following block.
    //         It looks that they need it to call ensureLayoutForGlyphRange but do not know when it needed
    //         What I changed was the way calc "glyphRec". Not its using [self boundingRectForGlyphIndex] which coniders
    //         text folding when calc the rect.
    /*
	BOOL isBlankLine =
		(location == [[self string] length] || isNewLine([[self string] characterAtIndex:location])) &&
		(location == 0 || isNewLine([[self string] characterAtIndex:location-1]));

    NSRange characterRange;
    characterRange.location = location;
    characterRange.length = isBlankLine ? 0 : 1;
    
    // Must call ensureLayoutForGlyphRange: to fix a bug where it will not scroll
    // to the appropriate glyph due to non contiguous layout
    NSRange glyphRange = [[_view layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
    [[_view layoutManager] ensureLayoutForGlyphRange:NSMakeRange(0, glyphRange.location + glyphRange.length)];
     */
    
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSRect glyphRect = [self boundingRectForGlyphIndex:location];

    CGFloat glyphLeft = NSMidX(glyphRect) - NSWidth(glyphRect) / 2.0f;
    CGFloat glyphRight = NSMidX(glyphRect) + NSWidth(glyphRect) / 2.0f;

    NSRect contentRect = [[scrollView contentView] bounds];
    CGFloat viewLeft = contentRect.origin.x;
    CGFloat viewRight = contentRect.origin.x + NSWidth(contentRect);

    NSPoint scrollPoint = contentRect.origin;
    if (glyphRight > viewRight){
        scrollPoint.x = glyphLeft - NSWidth(contentRect) / 2.0f;
    }else if (glyphLeft < viewLeft){
        scrollPoint.x = glyphRight - NSWidth(contentRect) / 2.0f;
    }

    CGFloat glyphBottom = NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f;
    CGFloat glyphTop = NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f;

    CGFloat viewTop = contentRect.origin.y;
    CGFloat viewBottom = contentRect.origin.y + NSHeight(contentRect);

    if (glyphTop < viewTop){
        if (viewTop - glyphTop > NSHeight(contentRect)){
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.0f;
        }else{
            scrollPoint.y = glyphTop;
        }
    }else if (glyphBottom > viewBottom){
        if (glyphBottom - viewBottom > NSHeight(contentRect)) {
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.0f;
        }else{
            scrollPoint.y = glyphBottom - NSHeight(contentRect);
        }
    }

    scrollPoint.x = MAX(0, scrollPoint.x);
    scrollPoint.y = MAX(0, scrollPoint.y);

    [[scrollView  contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (NSUInteger)cursorBottom:(NSNumber*)count { // L
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    bottom.y += [[scrollView contentView] bounds].size.height - NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:bottom], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorCenter:(NSNumber*)count { // M
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSPoint center = [[scrollView contentView] bounds].origin;
    center.y += [[scrollView contentView] bounds].size.height / 2;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:center], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorTop:(NSNumber*)count { // H
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = [[scrollView contentView] bounds].origin;
    top.y += NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:top], 0 };
   
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

/**
 * Takes point in view and returns its index.
 * This method automatically convert the "folded index" to "real index"
 * When some characters are folded( like placeholders) the pure index for a specifix point is
 * less than really index in the string.
 **/
- (NSUInteger)glyphIndexForPoint:(NSPoint)point {
	NSUInteger index = [[_view layoutManager] glyphIndexForPoint:point inTextContainer:[_view textContainer]];
    DVTFoldingTextStorage* storage = [(DVTSourceTextView*)_view textStorage];
    return [storage realLocationForFoldedLocation:index];
}

- (NSRect)boundingRectForGlyphIndex:(NSUInteger)glyphIndex {
    DVTFoldingTextStorage* storage = [(DVTSourceTextView*)_view textStorage];
    NSUInteger foldedIndex = [storage foldedLocationForRealLocation:glyphIndex];
    NSRect glyphRect;
    if( [self realLength] >= glyphIndex ){ // TODO: This should be implemented in isEOF.
        glyphRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(foldedIndex, 0)  inTextContainer:[_view textContainer]];
    }else{
        glyphRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(foldedIndex, 1)  inTextContainer:[_view textContainer]];
    }
    return glyphRect;
}

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

- (void)moveForward {
    [self move:XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
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
    [self changeSelectionMode:MODE_VISUAL_NONE];
}

- (void)redo {
	[[_view undoManager] redo];
    [self _syncStateFromView];
    [self changeSelectionMode:MODE_VISUAL_NONE];
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

// Obsolete
// This is here because only compatibility reason
- (void)setSelectedRange:(NSRange)range {
    [self _setSelectedRange:range];
    [self _syncStateFromView];
    /*
    LOG_STATE();
    @try{
        _insertionPoint = range.location;
        _selectionBegin = NSNotFound;;
        if( 0 != range.length ){
            _selectionBegin = _insertionPoint;
        }
        [self _syncState];
    }@catch (NSException *exception) {
        ERROR_LOG(@"main:Caught %@:%@", [exception name], [exception reason]);
    }
    LOG_STATE();
     */
}

//////////////////////
// Internal Methods //
//////////////////////
/**
 * Returns end position of the specified motion.
 * Note that this may return NSNotFound
 **/
- (NSUInteger)_getPositionFrom:(NSUInteger)current Motion:(XVimMotion*)motion{
    NSUInteger nextPos = current;
    NSUInteger tmpPos = NSNotFound;
    switch (motion.motion) {
        case MOTION_NONE:
            // Do nothing
            break;
        case MOTION_FORWARD:
            nextPos = [self next:current count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_BACKWARD:
            nextPos = [self prev:_insertionPoint count:motion.count option:motion.option ];
            break;
        case MOTION_WORD_FORWARD:
            nextPos = [self wordsForward:current count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_WORD_BACKWARD:
            nextPos = [self wordsBackward:current count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_FORWARD:
            nextPos = [self endOfWordsForward:current count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_BACKWARD:
            nextPos = [self endOfWordsBackward:current count:motion.count option:motion.option];
            break;
        case MOTION_LINE_FORWARD:
            nextPos = [self nextLine:current column:_preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_LINE_BACKWARD:
            nextPos = [self prevLine:current column:_preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_BEGINNING_OF_LINE:
            nextPos = [self firstOfLine:current];
            if( nextPos == NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_END_OF_LINE:
            tmpPos = [self nextLine:current column:0 count:motion.count-1 option:MOTION_OPTION_NONE];
            nextPos = [self endOfLine:tmpPos];
            if( nextPos == NSNotFound){
                nextPos = tmpPos;
            }
            break;
        case MOTION_SENTENCE_FORWARD:
            nextPos = [self sentencesForward:current count:motion.count option:motion.option];
            break;
        case MOTION_SENTENCE_BACKWARD:
            nextPos = [self sentencesBackward:current count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_FORWARD:
            nextPos = [self paragraphsForward:current count:motion.count option:motion.option];
            if( nextPos != NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_PARAGRAPH_BACKWARD:
            nextPos = [self paragraphsBackward:current count:motion.count option:motion.option];
            if( nextPos != NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_NEXT_FIRST_NONBLANK:
            nextPos = [self nextLine:current column:0 count:motion.count option:motion.option];
            tmpPos = [self nextNonBlankInALine:nextPos];
            if( NSNotFound != tmpPos ){
                nextPos = tmpPos;
            }
            break;
        case MOTION_PREV_FIRST_NONBLANK:
            nextPos = [self prevLine:current column:0 count:motion.count option:motion.option];
            tmpPos = [self nextNonBlankInALine:nextPos];
            if( NSNotFound != tmpPos ){
                nextPos = tmpPos;
            }
            break;
        case MOTION_FIRST_NONBLANK:
            nextPos = [self headOfLineWithoutSpaces:current];
            if( NSNotFound == nextPos ){
                nextPos = current;
            }
            break;
        case MOTION_LINENUMBER:
            nextPos = [self positionAtLineNumber:motion.line column:0];
            if (nextPos == NSNotFound) {
                nextPos = [self firstOfLine:[self endOfFile]];
            }
            break;
        case MOTION_PERCENT:
            nextPos = [self positionAtLineNumber:1 + ([self numberOfLines]-1) * motion.count/100];
            if (nextPos == NSNotFound) {
                nextPos = [self firstOfLine:[self endOfFile]];
            }
            break;
        case MOTION_NEXT_MATCHED_ITEM:
            nextPos = [self positionOfMatchedPair:current];
            break;
        case MOTION_LASTLINE:
            nextPos = [self firstOfLine:[self endOfFile]];
            break;
        case TEXTOBJECT_WORD:
        case TEXTOBJECT_BIGWORD:
        case TEXTOBJECT_BRACES:
        case TEXTOBJECT_PARAGRAPH:
        case TEXTOBJECT_PARENTHESES:
        case TEXTOBJECT_SENTENCE:
        case TEXTOBJECT_ANGLEBRACKETS:
        case TEXTOBJECT_SQUOTE:
        case TEXTOBJECT_DQUOTE:
        case TEXTOBJECT_TAG:
        case TEXTOBJECT_BACKQUOTE:
        case TEXTOBJECT_SQUAREBRACKETS:
            break;
        case MOTION_LINE_COLUMN:
            nextPos = [self positionAtLineNumber:motion.line column:motion.column];
            if( NSNotFound == nextPos ){
                nextPos = current;
            }
            break;
        case MOTION_POSITION:
            nextPos = motion.position;
            break;
    }
    TRACE_LOG(@"nextPos: %u", nextPos);
    return nextPos;
}

- (void)_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve{
    // This method only update the internal state(like _insertionPoint)
    
    if( pos > [_view string].length){
        DEBUG_LOG(@"Position specified exceeds the length of the text");
        pos = [_view string].length;
    }
    
    if( _cursorMode == CURSOR_MODE_COMMAND && !(_selectionMode == MODE_BLOCK)){
        _insertionPoint = [self convertToValidCursorPositionForNormalMode:pos];
    }else{
        _insertionPoint = pos;
    }
    
    if( !preserve ){
        _preservedColumn = [self columnNumber:_insertionPoint];
    }
    
    DEBUG_LOG(@"New Insertion Point:%d     Preserved Column:%d", _insertionPoint, _preservedColumn);
}

- (void)_deleteLine:(NSUInteger)lineNum{
    NSUInteger pos = [self positionAtLineNumber:lineNum];
    if( NSNotFound == pos ){
        return;
    }
    
    if( [self isLastLine:pos] ){
        // To delete last line we need to delete newline char before this line
        NSUInteger start = pos;
        if( pos != 0 ){
            start = pos - 1;
        }
        
        // Delete upto end of line of the last line.
        NSUInteger end = [self endOfLine:pos];
        if( NSNotFound == end ){
            // The last line is blank-EOF line
            [_view insertText:@"" replacementRange:NSMakeRange(start, end-start+1)];
        }else{
            [_view insertText:@"" replacementRange:NSMakeRange(start, end-start)];
        }
    }else{
        NSUInteger end = [self tailOfLine:pos];
        NSAssert( end != NSNotFound, @"Only when it is last line it return NSNotFound");
        [_view insertText:@"" replacementRange:NSMakeRange(pos, end-pos+1)]; //delete including newline
    }
}

- (void)_adjustCursorPosition{
    if( ![self isValidCursorPosition:_insertionPoint] ){
        NSRange placeholder = [(DVTSourceTextView*)_view rangeOfPlaceholderFromCharacterIndex:_insertionPoint forward:NO wrap:NO limit:0];
        if( placeholder.location != NSNotFound && _insertionPoint == (placeholder.location + placeholder.length)){
            //The condition here means that just before current insertion point is a placeholder.
            //So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
            [self _moveCursor:placeholder.location preserveColumn:NO];
        }else{
            [self _moveCursor:_insertionPoint-1 preserveColumn:NO];
        }
    }
    
}
- (void)_syncStateFromView{
    // TODO: handle block selection (if selectedRanges have multiple ranges )
    NSRange r = [_view selectedRange];
    if( r.length == 0 ){
        _selectionMode = MODE_VISUAL_NONE;
        [self _moveCursor:r.location preserveColumn:NO];
        _selectionBegin = _insertionPoint;
    }else{
        _selectionMode = MODE_CHARACTER;
        NSSelectionAffinity affinity = [_view selectionAffinity];
        _selectionBegin = r.location;
        if( affinity == NSSelectionAffinityDownstream ){
            [self _moveCursor:r.location + r.length - 1 preserveColumn:NO];
        }else{
            [self _moveCursor:r.location preserveColumn:NO];
        }
    }
    
    // Apply it back to _view
    [self _syncState];
}

/**
 * Applies internal state to underlying view (_view).
 * This update _view's property and applies the visual effect on it.
 * All the state need to express Vim is held by this class and
 * we use _view to express it visually.
 **/
- (void)_syncState{
    // Reset current selection
    if( _cursorMode == CURSOR_MODE_COMMAND ){
        [self _adjustCursorPosition];
    }
    [_view setSelectedRanges:[self _selectedRanges]];
    [self scrollTo:_insertionPoint];
}

// _setSelectedRange is an internal method
// This is used when you want to call [_view setSelectedRrange];
// The difference is that this checks the bounds(range can not be include EOF) and protect from Assersion
// Cursor can be on EOF but EOF can not be selected.
// It means that
//   - setSelectedRange:NSMakeRange( indexOfEOF, 0 )   is allowed
//   - setSelectedRange:NSMakeRange( indexOfEOF, 1 )   is not allowed
- (void)_setSelectedRange:(NSRange)range{
    if( [self isEOF:range.location] ){
        [_view setSelectedRange:NSMakeRange(range.location,0)];
        return;
    }
    if( 0 == range.length ){
        // No need to check bounds
    }else{
        NSUInteger lastIndex = range.location + range.length - 1;
        if( [self isEOF:lastIndex] ){
            range.length--;
        }else{
            // No need to change the selection area
        }
    }
    [_view setSelectedRange:range];
    LOG_STATE();
}

- (void)dumpState{
    LOG_STATE();
}

@end
