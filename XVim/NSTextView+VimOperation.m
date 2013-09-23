//
//  NSTextView+VimOperation.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/3/13.
//
//

#if (XVIM_XCODE_VERSION==5)
#define __XCODE5__
#endif 

#define __USE_DVTKIT__

#ifdef __USE_DVTKIT__
#import "DVTKit.h"
#import "IDEKit.h"
#endif

#import "Utils.h"
#import "NSString+VimHelper.h"
#import "NSObject+ExtraData.h"
#import "NSTextView+VimOperation.h"
#import "NSTextStorage+VimOperation.h"
#import "Logger.h"

#define LOG_STATE() TRACE_LOG(@"mode:%d length:%d cursor:%d ip:%d begin:%d line:%d column:%d preservedColumn:%d", \
                            self.selectionMode,            \
                            [self.textStorage string].length,       \
                            self.cursorMode,               \
                            self.insertionPoint,           \
                            self.selectionBegin,           \
                            self.insertionLine,            \
                            self.insertionColumn,          \
                            self.preservedColumn )

// These property declarations for for accessing them as readwrite from inside this category
@interface NSTextView ()
@property NSUInteger insertionPoint;
@property XVimPosition insertionPosition;
//@property NSUInteger insertionColumn;  // This is readonly also internally
//@property NSUInteger insertionLine;    // This is readonly also internally
@property NSUInteger preservedColumn;
@property NSUInteger selectionBegin;
//@property XVimPosition selectionBeginPosition; // This is readonly also internally
@property XVIM_VISUAL_MODE selectionMode;
@property CURSOR_MODE cursorode;
@property(strong) NSURL* documentURL;
@property(readonly) NSMutableArray* foundRanges;

// Internal properties
@property(strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
@end

@interface NSTextView(VimOperationPrivate)
@property BOOL xvim_lockSyncStateFromView;
- (void)xvim_deleteLine:(NSUInteger)lineNum;
- (void)xvim_setSelectedRange:(NSRange)range;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState; // update self's properties with our variables
- (NSArray*)xvim_selectedRanges;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)xvim_yankRanges:(NSArray*)ranges withType:(MOTION_TYPE)type;
- (void)xvim_shfit:(XVimMotion*)motion right:(BOOL)right;
- (void)xvim_indentCharacterRange:(NSRange)range;
- (void)xvim_scrollCommon_moveCursorPos:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (NSUInteger)xvim_lineNumberFromBottom:(NSUInteger)count;
- (NSUInteger)xvim_lineNumberAtMiddle;
- (NSUInteger)xvim_lineNumberFromTop:(NSUInteger)count;
- (NSRange)xvim_search:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward;
- (void)xvim_swapCaseForRange:(NSRange)range;
@end

@implementation NSTextView (VimOperation)

#pragma mark Properties

/**
 * Properties in this category uses NSObject+ExtraData to
 * store additional properties.
 **/

- (NSUInteger)insertionPoint{
    id ret = [self dataForName:@"insertionPoint"];
    return nil == ret ? 0 : [ret unsignedIntegerValue];
}

- (void)setInsertionPoint:(NSUInteger)insertion{
    [self setUnsignedInteger:insertion forName:@"insertionPoint"];
}

- (XVimPosition)insertionPosition{
    return XVimMakePosition(self.insertionLine, self.insertionColumn);
}

- (void)setInsertionPosition:(XVimPosition)pos{
    // Not implemented yet (Just update corresponding insertionPoint)
}

- (NSUInteger)insertionColumn{
    return [self.textStorage columnNumber:self.insertionPoint];
}

- (NSUInteger)insertionLine{
    return [self.textStorage lineNumber:self.insertionPoint];
}

- (NSUInteger)preservedColumn{
    id ret = [self dataForName:@"preservedColumn"];
    return nil == ret ? 0 : [ret unsignedIntegerValue];
}

- (void)setPreservedColumn:(NSUInteger)preservedColumn{
    TRACE_LOG(@"%d" , preservedColumn);
    [self setUnsignedInteger:preservedColumn forName:@"preservedColumn"];
}

- (NSUInteger)selectionBegin{
    id ret = [self dataForName:@"selectionBegin"];
    return nil == ret ? 0 : [ret unsignedIntegerValue];
}

- (void)setSelectionBegin:(NSUInteger)selectionBegin{
    [self setUnsignedInteger:selectionBegin forName:@"selectionBegin"];
}

- (XVimPosition)selectionBeginPosition{
    return XVimMakePosition([self.textStorage lineNumber:self.selectionBegin], [self.textStorage columnNumber:self.selectionBegin]);
}

- (NSUInteger)numberOfSelectedLines{
    if( XVIM_VISUAL_NONE == self.selectionMode ){
        return 0;
    }
    
    NSUInteger min = MIN(self.insertionPoint,self.selectionBegin);
    NSUInteger max = MAX(self.insertionPoint,self.selectionBegin);
    NSUInteger lineMin = [self.textStorage lineNumber:min];
    NSUInteger lineMax = [self.textStorage lineNumber:max];
    
    return lineMax - lineMin + 1;
}

- (NSUInteger)numberOfSelectedColumns{
    if( XVIM_VISUAL_NONE == self.selectionMode ){
        return 0;
    }
    
    NSUInteger min = MIN(self.insertionPoint,self.selectionBegin);
    NSUInteger max = MAX(self.insertionPoint,self.selectionBegin);
    NSUInteger lineMin = [self.textStorage lineNumber:min];
    NSUInteger lineMax = [self.textStorage lineNumber:max];
    NSUInteger columnMin = MIN( [self.textStorage columnNumber:min], [self.textStorage columnNumber:max]);
    NSUInteger columnMax = MAX( [self.textStorage columnNumber:min], [self.textStorage columnNumber:max]);
    
    if( XVIM_VISUAL_CHARACTER == self.selectionMode ){
        if( lineMin == lineMax ){
            return max - min + 1;
        }else{ // If it is multipe lines return number of columns selected in the last line.
            return [self.textStorage columnNumber:max] + 1; // Columns number starts from 0
        }
    }else if( XVIM_VISUAL_LINE == self.selectionMode ){
        return NSUIntegerMax;
    }else if( XVIM_VISUAL_BLOCK == self.selectionMode ){
        return columnMax - columnMin + 1;
    }else{
        NSAssert(FALSE, @"Should not be reached here");
        return 0;
    }
}

- (XVIM_VISUAL_MODE) selectionMode{
    id ret = [self dataForName:@"selectionMode"];
    return nil == ret ? XVIM_VISUAL_NONE : (XVIM_VISUAL_MODE)[ret integerValue];
}

- (void)setSelectionMode:(XVIM_VISUAL_MODE)selectionMode{
    [self setInteger:selectionMode forName:@"selectionMode"];
}

- (CURSOR_MODE) cursorMode{
    id ret = [self dataForName:@"cursorMode"];
    return nil == ret ? CURSOR_MODE_COMMAND : (CURSOR_MODE)[ret integerValue];
}

- (void)setCursorMode:(CURSOR_MODE)cursorMode{
    [self setInteger:cursorMode forName:@"cursorMode"];
}

- (NSURL*)documentURL{
#ifdef __USE_DVTKIT__
    if( [self.delegate isKindOfClass:[IDEEditor class]] ){
        return [(IDEEditorDocument*)((IDEEditor*)self.delegate).document fileURL];
    }else{
        return nil;
    }
#else
    return nil;
#endif
}

- (void)setXvimDelegate:(id)xvimDelegate{
    [self setData:xvimDelegate forName:@"xvimDelegate"];
}

- (id)xvimDelegate{
    return [self dataForName:@"xvimDelegate"];
}

- (BOOL)needsUpdateFoundRanges{
    id ret = [self dataForName:@"needsUpdateFoundRanges"];
    return nil == ret ? NO : [ret boolValue];
}

- (void)setNeedsUpdateFoundRanges:(BOOL)needsUpdateFoundRanges{
    [self setBool:needsUpdateFoundRanges forName:@"needsUpdateFoundRanges"];
}

- (NSMutableArray*)foundRanges{
    id ranges = [self dataForName:@"foundRanges"];
    if( nil == ranges ){
        ranges = [[[NSMutableArray alloc] init] autorelease];
        [self setData:ranges forName:@"foundRanges"];
    }
    return ranges;
}

#pragma mark Internal properties

- (NSString*) lastYankedText{
    return [self dataForName:@"lastYankedText"];
}

- (void)setLastYankedText:(NSString*)text{
    [self setData:[NSString stringWithString:text] forName:@"lastYankedText"];
}

- (TEXT_TYPE) lastYankedType{
    return (TEXT_TYPE)[[self dataForName:@"lastYankedType"] integerValue];
}

- (void) setLastYankedType:(TEXT_TYPE)type{
    [self setInteger:type forName:@"lastYankedType"];
}

- (long long)currentLineNumber {
#ifdef __USE_DVTKIT__
    if( [self isKindOfClass:[DVTSourceTextView class]] ){
        return [(DVTSourceTextView*)self _currentLineNumber];
    }
#else
#error You must implement here.
#endif
    NSAssert(NO, @"You must implement here if you do not use this with DVTSourceTextView");
    return -1;
}


- (NSString*)xvim_string{
    return [self.textStorage xvim_string];
}

#pragma mark Status

- (NSUInteger)xvim_numberOfLinesInVisibleRect{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSAssert( glyphRect.size.height != 0 , @"Need to fix the code here if the height of current selected character can be 0 here" );
    return [scrollView contentView].bounds.size.height / glyphRect.size.height;
}



#pragma mark Changing state


- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode{
    if( self.selectionMode == XVIM_VISUAL_NONE && mode != XVIM_VISUAL_NONE ){
        self.selectionBegin = self.insertionPoint;
    }else if( self.selectionMode != XVIM_VISUAL_NONE && mode == XVIM_VISUAL_NONE){
        self.selectionBegin = NSNotFound;
    }
    self.selectionMode = mode;
    [self xvim_syncState];
    return;
}

- (void)xvim_escapeFromInsert{
    if( self.cursorMode == CURSOR_MODE_INSERT ){
        self.cursorMode = CURSOR_MODE_COMMAND;
        if(![self.textStorage isBOL:self.insertionPoint]){
            [self xvim_moveCursor:self.insertionPoint-1 preserveColumn:NO];
        }
        [self xvim_syncState];
    }
}

- (void)xvim_setWrapsLines:(BOOL)wraps {
#ifdef __USE_DVTKIT__
    if( [self isKindOfClass:[DVTSourceTextView class]]){
        [(DVTSourceTextView*)self  setWrapsLines:wraps];
    }
#endif
}

#pragma mark Operations
/**
 * Adjust cursor position if the position is not valid as normal mode cursor position
 * This method may changes selected range of the view.
 **/
- (void)xvim_adjustCursorPosition{
    // If the current cursor position is not valid for normal mode move it.
    if( ![self.textStorage isValidCursorPosition:[self selectedRange].location] ){
        NSRange currentRange = [self selectedRange];
        [self xvim_selectPreviousPlaceholder];
        NSRange prevPlaceHolder = [self selectedRange];
        if( currentRange.location != prevPlaceHolder.location && currentRange.location == (prevPlaceHolder.location + prevPlaceHolder.length) ){
            //The condition here means that just before current insertion point is a placeholder.
            //So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
        }else{
            [self setSelectedRange:NSMakeRange(currentRange.location-1, 0)];
        }
    }
    return;
}

- (void)xvim_moveToPosition:(XVimPosition)pos{
    [self xvim_moveCursor:[self.textStorage positionAtLineNumber:pos.line column:pos.column] preserveColumn:NO];
    [self xvim_syncState];
}

- (void)xvim_move:(XVimMotion*)motion{
    XVimRange r = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
    if( r.end == NSNotFound ){
        return;
    }
    
    if( self.selectionMode != XVIM_VISUAL_NONE && [motion isTextObject]){
        if( self.selectionMode == XVIM_VISUAL_LINE){
            // Motion with text object in VISUAL LINE changes visual mode to VISUAL CHARACTER
            [self setSelectionMode:XVIM_VISUAL_CHARACTER];
        }
        
        if( self.insertionPoint < self.selectionBegin ){
            // When insertionPoint < selectionBegin it only changes insertion point to begining of the text object
            [self xvim_moveCursor:r.begin preserveColumn:NO];
        }else{
            // Text object expands one text object ( the text object under insertion point + 1 )
            if( ![self.textStorage isEOF:self.insertionPoint+1]){
                r = [self xvim_getMotionRange:self.insertionPoint+1 Motion:motion];
            }
            if( self.selectionBegin > r.begin ){
                self.selectionBegin = r.begin;
            }
            [self xvim_moveCursor:r.end preserveColumn:NO];
        }
    }else{
        switch( motion.motion ){
            case MOTION_LINE_BACKWARD:
            case MOTION_LINE_FORWARD:
            case MOTION_LASTLINE:
            case MOTION_LINENUMBER:
                // TODO: Preserve column option can be included in motion object
                [self xvim_moveCursor:r.end preserveColumn:YES];
                break;
            default:
                [self xvim_moveCursor:r.end preserveColumn:NO];
                break;
        }
    }
    [self xvim_syncState];
}

- (void)xvim_delete:(XVimMotion*)motion{
    NSAssert( !(self.selectionMode == XVIM_VISUAL_NONE && motion == nil), @"motion must be specified if current selection mode is not visual");
    if( self.insertionPoint == 0 && [[self xvim_string] length] == 0 ){
        return ;
    }
    
    NSUInteger insertionPointAfterDelete = self.insertionPoint;
    BOOL keepInsertionPoint = NO;
    if( self.selectionMode != XVIM_VISUAL_NONE ){
        insertionPointAfterDelete = [[[self xvim_selectedRanges] objectAtIndex:0] rangeValue].location;
        keepInsertionPoint = YES;
    }
    
    motion.info->deleteLastLine = NO;
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        NSRange r;
        XVimRange motionRange = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if( motionRange.end == NSNotFound ){
            return;
        }
        // We have to treat some special cases
        // When a cursor get end of line with "l" motion, make the motion type to inclusive.
        // This make you to delete the last character. (if its exclusive last character never deleted with "dl")
        if( motion.motion == MOTION_FORWARD && motion.info->reachedEndOfLine ){
            if( motion.type == CHARACTERWISE_EXCLUSIVE ){
                motion.type = CHARACTERWISE_INCLUSIVE;
            }else if( motion.type == CHARACTERWISE_INCLUSIVE ){
                motion.type = CHARACTERWISE_EXCLUSIVE;
            }
        }
        if( motion.motion == MOTION_WORD_FORWARD ){
            if ( (motion.info->isFirstWordInLine && motion.info->lastEndOfLine != NSNotFound )) {
                // Special cases for word move over a line break.
                motionRange.end = motion.info->lastEndOfLine;
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
            else if( motion.info->reachedEndOfLine ){
                if( motion.type == CHARACTERWISE_EXCLUSIVE ){
                    motion.type = CHARACTERWISE_INCLUSIVE;
                }else if( motion.type == CHARACTERWISE_INCLUSIVE ){
                    motion.type = CHARACTERWISE_EXCLUSIVE;
                }
            }
        }
        r = [self xvim_getOperationRangeFrom:motionRange.begin To:motionRange.end Type:motion.type];
        if( motion.type == LINEWISE && [self.textStorage isLastLine:motionRange.end]){
            if( r.location != 0 ){
                motion.info->deleteLastLine = YES;
                r.location--;
                r.length++;
            }
        }
        [self xvim_yankRanges:[NSArray arrayWithObject:[NSValue valueWithRange:r]] withType:motion.type];
        [self xvim_setSelectedRange:r];
    }else{
        // Currently not supportin deleting EOF with selection mode.
        // This is because of the fact that NSTextView does not allow select EOF
        [self xvim_yankRanges:[self xvim_selectedRanges] withType:motion.type];
    }
    
    [self delete:nil];
    
    [self.xvimDelegate textView:self didDelete:self.lastYankedText  withType:self.lastYankedType];
    
    
    if(keepInsertionPoint){
        [self xvim_moveCursor:insertionPointAfterDelete preserveColumn:NO];
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_change:(XVimMotion*)motion{
    BOOL insertNewline = NO;
    if( motion.type == LINEWISE || self.selectionMode == XVIM_VISUAL_LINE){
        // 'cc' deletes the lines but need to keep the last newline.
        // So insertNewline as 'O' does before entering insert mode
        insertNewline = YES;
    }
    
    // "cw" is like "ce" if the cursor is on a word ( in this case blank line is not treated as a word )
    if( motion.motion == MOTION_WORD_FORWARD && [self.textStorage isNonblank:self.insertionPoint] ){
        motion.motion = MOTION_END_OF_WORD_FORWARD;
        motion.type = CHARACTERWISE_INCLUSIVE;
    }
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_delete:motion];
    if( motion.info->deleteLastLine){
        [self xvim_insertNewlineAboveLine:[self.textStorage lineNumber:self.insertionPoint]];
    }
    else if( insertNewline ){
        [self xvim_insertNewlineAboveLine:[self.textStorage lineNumber:self.insertionPoint]];
    }else{
        
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [self xvim_syncState];
}

- (void)xvim_yank:(XVimMotion*)motion{
    NSAssert( !(self.selectionMode == XVIM_VISUAL_NONE && motion == nil), @"motion must be specified if current selection mode is not visual");
    NSUInteger insertionPointAfterYank = self.insertionPoint;
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        NSRange r;
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if( NSNotFound == to.end ){
            return;
        }
        // We have to treat some special cases (same as delete)
        if( motion.motion == MOTION_FORWARD && motion.info->reachedEndOfLine){
            motion.type = CHARACTERWISE_INCLUSIVE;
        }
        if( motion.motion == MOTION_WORD_FORWARD ){
            if ( (motion.info->isFirstWordInLine && motion.info->lastEndOfLine != NSNotFound )) {
                // Special cases for word move over a line break.
                to.end = motion.info->lastEndOfLine;
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
            else if( motion.info->reachedEndOfLine ){
                if( motion.type == CHARACTERWISE_EXCLUSIVE ){
                    motion.type = CHARACTERWISE_INCLUSIVE;
                }else if( motion.type == CHARACTERWISE_INCLUSIVE ){
                    motion.type = CHARACTERWISE_EXCLUSIVE;
                }
            }
        }
        r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
        BOOL eof = [self.textStorage isEOF:to.end];
        BOOL blank = [self.textStorage isBlankline:to.end];
        if( motion.type == LINEWISE && blank && eof){
            if( r.location != 0 ){
                r.location--;
                r.length++;
            }
        }
        [self xvim_yankRanges:[NSArray arrayWithObject:[NSValue valueWithRange:r]] withType:motion.type];
    }else{
        insertionPointAfterYank = self.insertionPoint < self.selectionBegin ? self.insertionPoint : self.selectionBegin;
        [self xvim_yankRanges:[self xvim_selectedRanges] withType:motion.type];
    }
    
    [self.xvimDelegate textView:self didYank:self.lastYankedText  withType:self.lastYankedType];
    
    [self xvim_moveCursor:insertionPointAfterYank preserveColumn:NO];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count{
    TRACE_LOG(@"text:%@  type:%d   afterCursor:%d   count:%d", text, type, after, count);
    if( self.selectionMode != XVIM_VISUAL_NONE ){
        // FIXME: Make them not to change text from register...
        text = [NSString stringWithString:text]; // copy string because the text may be changed with folloing delete if it is from the same register...
        [self xvim_delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 1)];
        after = NO;
    }
    
    NSUInteger insertionPointAfterPut = self.insertionPoint;
    NSUInteger targetPos = self.insertionPoint;
    if( type == TEXT_TYPE_CHARACTERS ){
        //Forward insertion point +1 if after flag if on
        if( 0 != text.length ){
            if (![self.textStorage isNewline:self.insertionPoint] && after) {
                targetPos++;
            }
            insertionPointAfterPut = targetPos;
            [self xvim_setSelectedRange:NSMakeRange(targetPos,0)];
            for(NSUInteger i = 0; i < count ; i++ ){
                [self insertText:text];
            }
            insertionPointAfterPut += text.length*count - 1;
        }
    }else if( type == TEXT_TYPE_LINES ){
        if( after ){
            [self xvim_insertNewlineBelow];
            targetPos = self.insertionPoint;
        }else{
            targetPos= [self.textStorage beginningOfLine:self.insertionPoint];
        }
        insertionPointAfterPut = self.insertionPoint;
        [self xvim_setSelectedRange:NSMakeRange(targetPos,0)];
        for(NSUInteger i = 0; i < count ; i++ ){
            if( after && i == count-1 ){
                // delete newline at the end. (TEXT_TYPE_LINES always have newline at the end of the text)
                NSString* t = [text  substringToIndex:text.length-1];
                [self insertText:t];
            } else{
                [self insertText:text];
            }
        }
    }else if( type == TEXT_TYPE_BLOCK ){
        //Forward insertion point +1 if after flag if on
        if (![self.textStorage isNewline:self.insertionPoint] && ![self.textStorage isEOF:self.insertionPoint] && after) {
            self.insertionPoint++;
        }
        insertionPointAfterPut = self.insertionPoint;
        NSUInteger insertPos = self.insertionPoint;
        NSUInteger column = [self.textStorage columnNumber:insertPos];
        NSUInteger startLine = [self.textStorage lineNumber:insertPos];
        NSArray* lines = [text componentsSeparatedByString:@"\n"];
        for( NSUInteger i = 0 ; i < lines.count ; i++){
            NSString* line = [lines objectAtIndex:i];
            NSUInteger targetLine = startLine + i;
            NSUInteger head = [self.textStorage positionAtLineNumber:targetLine];
            if( NSNotFound == head ){
                NSAssert( targetLine != 0, @"This should not be happen");
                [self xvim_insertNewlineBelowLine:targetLine-1];
                head = [self.textStorage positionAtLineNumber:targetLine];
            }
            NSAssert( NSNotFound != head , @"Head of the target line must be found at this point");
            
            // Find next insertion point
            NSUInteger max = [self.textStorage maxColumnAtLineNumber:[self.textStorage lineNumber:head]];
            NSAssert( max != NSNotFound , @"Should not be NSNotFound");
            if( column > max ){
                // If the line does not have enough column pad it with spaces
                NSUInteger spaces = column - max;
                NSUInteger end = [self.textStorage endOfLine:head];
                for( NSUInteger i = 0 ; i < spaces; i++){
                    [self insertText:@" " replacementRange:NSMakeRange(end,0)];
                }
            }
            for(NSUInteger i = 0; i < count ; i++ ){
                [self xvim_insertText:line line:targetLine column:column];
            }
        }
    }
    
    
    [self xvim_moveCursor:insertionPointAfterPut preserveColumn:NO];
    [self xvim_syncState];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_swapCase:(XVimMotion*)motion{
    if( self.insertionPoint == 0 && [[self xvim_string] length] == 0 ){
        return ;
    }
    
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        if( motion.motion == MOTION_NONE ){
            XVimMotion* m = XVIM_MAKE_MOTION(MOTION_FORWARD,CHARACTERWISE_EXCLUSIVE,LEFT_RIGHT_NOWRAP,motion.count);
            XVimRange r = [self xvim_getMotionRange:self.insertionPoint Motion:m];
            if( r.end == NSNotFound){
                return;
            }
            if( m.info->reachedEndOfLine ){
                [self xvim_swapCaseForRange:[self xvim_getOperationRangeFrom:r.begin To:r.end Type:CHARACTERWISE_INCLUSIVE]];
            }else{
                [self xvim_swapCaseForRange:[self xvim_getOperationRangeFrom:r.begin To:r.end Type:CHARACTERWISE_EXCLUSIVE]];
            }
            [self xvim_moveCursor:r.end preserveColumn:NO];
        }else{
            NSRange r;
            XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
            if( to.end == NSNotFound){
                return;
            }
            r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
            [self.undoManager beginUndoGrouping];
            [self xvim_swapCaseForRange:r];
            [self.undoManager endUndoGrouping];
            [self xvim_moveCursor:r.location preserveColumn:NO];
        }
    }else{
        NSArray* ranges = [self xvim_selectedRanges];
        for( NSValue* val in ranges){
            [self xvim_swapCaseForRange:[val rangeValue]];
        }
        [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self xvim_syncState];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    
}

- (void)xvim_makeLowerCase:(XVimMotion*)motion{
    if( self.insertionPoint == 0 && [[self xvim_string] length] == 0 ){
        return ;
    }
    
    NSString* s = [self xvim_string];
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        NSRange r;
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if( to.end == NSNotFound ){
            return;
        }
        r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
        [self insertText:[[s substringWithRange:r] lowercaseString] replacementRange:r];
        [self xvim_moveCursor:r.location preserveColumn:NO];
    }else{
        NSArray* ranges = [self xvim_selectedRanges];
        for( NSValue* val in ranges){
            [self insertText:[[s substringWithRange:val.rangeValue] lowercaseString] replacementRange:val.rangeValue];
        }
        [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self xvim_syncState];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_makeUpperCase:(XVimMotion*)motion{
    if( self.insertionPoint == 0 && [[self xvim_string] length] == 0 ){
        return ;
    }
    
    NSString* s = [self xvim_string];
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        NSRange r;
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if( to.end == NSNotFound ){
            return;
        }
        r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];  // TODO: use to.begin instead of insertionPoint
        [self insertText:[[s substringWithRange:r] uppercaseString] replacementRange:r];
        [self xvim_moveCursor:r.location preserveColumn:NO];
    }else{
        NSArray* ranges = [self xvim_selectedRanges];
        for( NSValue* val in ranges){
           [self insertText:[[s substringWithRange:val.rangeValue] uppercaseString] replacementRange:val.rangeValue];
        }
        [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self xvim_syncState];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    
}

- (BOOL)xvim_replaceCharacters:(unichar)c count:(NSUInteger)count{
    NSUInteger end = [self.textStorage endOfLine:self.insertionPoint];
    // Note : endOfLine may return one less than self.insertionPoint if self.insertionPoint is on newline
    if( NSNotFound == end ){
        return NO;
    }
    NSUInteger num = end - self.insertionPoint + 1;
    if( num < count ){
        return NO;
    }
    
    end = self.insertionPoint+count;
    for( NSUInteger pos = self.insertionPoint; pos < end; pos++){
        [self insertText:[NSString stringWithFormat:@"%c",c] replacementRange:NSMakeRange(pos, 1)];
    }
    return YES;
}

- (void)xvim_joinAtLineNumber:(NSUInteger)line{
    BOOL needSpace = NO;
    NSUInteger headOfLine = [self.textStorage positionAtLineNumber:line];
    if( headOfLine == NSNotFound){
        return;
    }

    NSUInteger tail = [self.textStorage endOfLine:headOfLine];
    if( [self.textStorage isEOF:tail] ){
        // This is the last line and nothing to join
        return;
    }
    
    // Check if we need to insert space between lines.
    NSUInteger lastOfLine = [self.textStorage lastOfLine:headOfLine];
    if( lastOfLine != NSNotFound ){
        // This is not blank line so we check if the last character is space or not .
        if( ![self.textStorage isWhitespace:lastOfLine] ){
            needSpace = YES;
        }
    }

    // Search in next line for the position to join(skip white spaces in next line)
    NSUInteger posToJoin = [self.textStorage nextLine:headOfLine column:0 count:1 option:MOTION_OPTION_NONE];
    NSUInteger tmp = [self.textStorage nextNonblankInLine:posToJoin];
    if( NSNotFound == tmp ){
        // Only white spaces are found in the next line
        posToJoin = [self.textStorage endOfLine:posToJoin];
    }else{
        posToJoin = tmp;
    }
    if( ![self.textStorage isEOF:posToJoin] && [self.string characterAtIndex:posToJoin] == ')' ){
        needSpace = NO;
    }
    
    // delete "tail" to "posToJoin" excluding the position of "posToJoin" and insert space if need.
    if( needSpace ){
        [self insertText:@" " replacementRange:NSMakeRange(tail, posToJoin-tail)];
    }else{
        [self insertText:@""  replacementRange:NSMakeRange(tail, posToJoin-tail)];
    }
    
    // Move cursor
    [self xvim_moveCursor:tail preserveColumn:NO];
}

- (void)xvim_join:(NSUInteger)count{
    NSUInteger start = [[[self xvim_selectedRanges] objectAtIndex:0] rangeValue].location;
    if( self.selectionMode != XVIM_VISUAL_NONE ){
        // If in selection mode ignore count
        NSRange lastSelection = [[[self xvim_selectedRanges] lastObject] rangeValue];
        NSUInteger end = lastSelection.location + lastSelection.length - 1;
        NSUInteger lineBegin = [self.textStorage lineNumber:start];
        NSUInteger lineEnd = [self.textStorage lineNumber:end];
        count = lineEnd - lineBegin ;
    }
    
    for( NSUInteger i = 0; i < count ; i++ ){
        [self xvim_joinAtLineNumber:[self.textStorage lineNumber:start]];
    }
    
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    return;
}

- (void)xvim_filter:(XVimMotion*)motion{
    if( self.insertionPoint == 0 && [[self xvim_string] length] == 0 ){
        return ;
    }
    
    NSUInteger insertionAfterFilter = self.insertionPoint;
    NSRange filterRange;
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if( to.end == NSNotFound ){
            return;
        }
        filterRange = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:LINEWISE];
    }else{
        insertionAfterFilter = [[[self xvim_selectedRanges] lastObject] rangeValue].location;
        NSUInteger start = [[[self xvim_selectedRanges] objectAtIndex:0] rangeValue].location;
        NSRange lastSelection = [[[self xvim_selectedRanges] lastObject] rangeValue];
        NSUInteger end = lastSelection.location + lastSelection.length - 1;
        filterRange  = NSMakeRange(start, end-start+1);
    }
    
	[self xvim_indentCharacterRange: filterRange];
    [self xvim_moveCursor:insertionAfterFilter preserveColumn:NO];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)xvim_shiftRight:(XVimMotion*)motion{
    [self xvim_shfit:motion right:YES];
}

- (void)xvim_shiftLeft:(XVimMotion*)motion{
    [self xvim_shfit:motion right:NO];
}

- (void)xvim_insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column{
    NSUInteger pos = [self.textStorage positionAtLineNumber:line column:column];
    if( pos == NSNotFound ){
        return;
    }
    [self insertText:str replacementRange:NSMakeRange(pos,0)];
}

- (void)xvim_insertNewlineBelowLine:(NSUInteger)line{
    NSAssert( line != 0, @"line number starts from 1");
    NSUInteger pos = [self.textStorage positionAtLineNumber:line];
    if( NSNotFound == pos ){
        return;
    }
    pos = [self.textStorage endOfLine:pos];
    [self insertText:@"\n" replacementRange:NSMakeRange(pos ,0)];
    [self xvim_moveCursor:pos+1 preserveColumn:NO];
    [self xvim_syncState];
}

- (void)xvim_insertNewlineBelow{
    NSUInteger l = self.insertionPoint;
    // TODO: Use self.insertionPoint to move cursor
    NSUInteger tail = [self.textStorage endOfLine:l];
    [self setSelectedRange:NSMakeRange(tail,0)];
    [self insertNewline:self];
}

- (void)xvim_insertNewlineAboveLine:(NSUInteger)line{
    NSAssert( line != 0, @"line number starts from 1");
    NSUInteger pos = [self.textStorage positionAtLineNumber:line];
    if( NSNotFound == pos ){
        return;
    }
    if( 1 != line ){
        [self xvim_insertNewlineBelowLine:line-1];
    }else{
        [self insertText:@"\n" replacementRange:NSMakeRange(0,0)];
        [self setSelectedRange:NSMakeRange(0,0)];
    }
}

- (void)xvim_insertNewlineAbove{
    NSUInteger l = self.insertionPoint;
    NSUInteger head = [self.textStorage firstOfLine:l];
    if( NSNotFound == head ){
        head = l;
    }
    if( 0 != head ){
        // TODO: Use self.insertionPoint to move cursor
        [self setSelectedRange:NSMakeRange(head-1,0)];
        [self insertNewline:self];
    }else{
        // TODO: Use self.insertionPoint to move cursor
        [self setSelectedRange:NSMakeRange(head,0)];
        [self insertNewline:self];
        [self setSelectedRange:NSMakeRange(0,0)];
    }
    
}

- (void)xvim_insertNewlineAboveAndInsert{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_insertNewlineAbove];
}

- (void)xvim_insertNewlineBelowAndInsert{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_insertNewlineBelow];
}

- (void)xvim_append{
    NSAssert(self.cursorMode == CURSOR_MODE_COMMAND, @"self.cursorMode shoud be CURSOR_MODE_COMMAND");
    self.cursorMode = CURSOR_MODE_INSERT;
    if( ![self.textStorage isEOF:self.insertionPoint] && ![self.textStorage isNewline:self.insertionPoint]){
        self.insertionPoint++;
    }
    [self xvim_insert];
}

- (void)xvim_insert{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_syncState];
}

- (void)xvim_appendAtEndOfLine{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [self xvim_moveCursor:[self.textStorage endOfLine:self.insertionPoint] preserveColumn:NO];
    [self xvim_syncState];
    
}

- (void)xvim_insertBeforeFirstNonblank{
    self.insertionPoint = [self.textStorage firstNonblankInLine:self.insertionPoint];
    [self xvim_insert];
}

- (void)xvim_overwriteCharacter:(unichar)c{
    if( self.insertionPoint >= [self.textStorage endOfFile] ){
        // Should not happen.
        return;
    }
    [self insertText:[NSString stringWithFormat:@"%c",c] replacementRange:NSMakeRange(self.insertionPoint,1)];
    return;
}

- (void)xvim_sortLinesFrom:(NSUInteger)line1 to:(NSUInteger)line2 withOptions:(XVimSortOptions)options{
    NSAssert( line1 > 0, @"line1 must be greater than 0.");
    NSAssert( line2 > 0, @"line2 must be greater than 0.");
    
    if( line2 < line1 ){
        //swap
        NSUInteger tmp = line1;
        line1 = line2;
        line2 = tmp;
    }
    
    NSRange characterRange = [self.textStorage characterRangeForLineRange:NSMakeRange(line1-1, line2-line1+1)];
    NSString *str = [[self xvim_string] substringWithRange:characterRange];
    
    NSMutableArray *lines = [[[str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy] autorelease];
    if ([[lines lastObject] length] == 0) {
        [lines removeLastObject];
    }
    [lines sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        NSStringCompareOptions compareOptions = 0;
        if (options & XVimSortOptionNumericSort) {
            compareOptions |= NSNumericSearch;
        }
        if (options & XVimSortOptionIgnoreCase) {
            compareOptions |= NSCaseInsensitiveSearch;
        }
        
        if (options & XVimSortOptionReversed) {
            return [str2 compare:str1 options:compareOptions];
        } else {
            return [str1 compare:str2 options:compareOptions];
        }
    }];
    
    if (options & XVimSortOptionRemoveDuplicateLines) {
        NSMutableIndexSet *removeIndices = [NSMutableIndexSet indexSet];
        // At this point the lines are already sorted
        [lines enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            if (idx < [lines count] - 1) {
                NSString *nextStr = [lines objectAtIndex:idx + 1];
                if ([str isEqualToString:nextStr]) {
                    [removeIndices addIndex:idx + 1];
                }
            }
        }];
        [lines removeObjectsAtIndexes:removeIndices];
    }
    
    NSUInteger insertionAfterOperation = characterRange.location;
    NSString *sortedLinesString = [[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    if( [self shouldChangeTextInRange:characterRange replacementString:sortedLinesString] ){
        [self replaceCharactersInRange:characterRange withString:sortedLinesString];
        [self didChangeText];
    }
    self.insertionPoint = insertionAfterOperation;
    [self xvim_syncState];
}

- (void)xvim_selectNextPlaceholder {
#ifdef __USE_DVTKIT__
    if( [self isKindOfClass:[DVTSourceTextView class]] ){
        [(DVTSourceTextView*)self selectNextPlaceholder:self];
    }
#endif
}

- (void)xvim_selectPreviousPlaceholder {
#ifdef __USE_DVTKIT__
    if( [self isKindOfClass:[DVTSourceTextView class]] ){
        [(DVTSourceTextView*)self selectPreviousPlaceholder:self];
    }
#endif
}

- (void)xvim_hideCompletions {
#ifdef __USE_DVTKIT__
    if( [self isKindOfClass:[DVTSourceTextView class]] ){
        [((DVTSourceTextView*)self).completionController hideCompletions];
    }
#endif
}

#pragma mark Scroll
- (NSUInteger)xvim_lineUp:(NSUInteger)index count:(NSUInteger)count {
  [self scrollLineUp:self];
  NSRect visibleRect = [[self enclosingScrollView] contentView].bounds;
  NSRect currentInsertionRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:[self textContainer]];
  NSPoint relativeInsertionPoint = SubPoint(currentInsertionRect.origin, visibleRect.origin);
  if (relativeInsertionPoint.y > visibleRect.size.height) {
    [self moveUp:self];
    NSPoint newPoint = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:[self textContainer]].origin;
    index = [self xvim_glyphIndexForPoint:newPoint];
  }
  return index;
}

- (NSUInteger)xvim_lineDown:(NSUInteger)index count:(NSUInteger)count {
  [self scrollLineDown:self];
  NSRect visibleRect = [[self enclosingScrollView] contentView].bounds;
  NSRect currentInsertionRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:[self textContainer]];
  if (currentInsertionRect.origin.y < visibleRect.origin.y) {
    [self moveDown:self];
    NSPoint newPoint = NSMakePoint(currentInsertionRect.origin.x, visibleRect.origin.y);
    index = [self xvim_glyphIndexForPoint:newPoint];
  }
  return index;
}

- (void)xvim_scroll:(CGFloat)ratio count:(NSUInteger)count{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat scrollSize = visibleRect.size.height * ratio * count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize ); // This may be beyond the beginning or end of document (intentionally)
    
    // Cursor position relative to left-top origin shold be kept after scroll ( Exception is when it scrolls beyond the beginning or end of document)
    NSRect currentInsertionRect = [self xvim_boundingRectForGlyphIndex:self.insertionPoint];
    NSPoint relativeInsertionPoint = SubPoint(currentInsertionRect.origin, visibleRect.origin);
    //TRACE_LOG(@"Rect:%f %f    realIndex:%d   foldedIndex:%d", currentInsertionRect.origin.x, currentInsertionRect.origin.y, self.insertionPoint, index);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = AddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    // TODO: consider blank-EOF line. Xcode does not return blank-EOF index with following method...
    NSUInteger cursorIndexAfterScroll= [self xvim_glyphIndexForPoint:cursorAfterScroll];
    
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [self xvim_boundingRectForGlyphIndex:cursorIndexAfterScroll];
    NSPoint relativeInsertionPointAfterScroll = SubPoint(insertionRectAfterScroll.origin, scrollPoint);
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
	
    cursorIndexAfterScroll = [self.textStorage firstNonblankInLine:cursorIndexAfterScroll];
    [self xvim_moveCursor:cursorIndexAfterScroll preserveColumn:NO];
    [self xvim_syncState];
    
}

- (void)xvim_scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{ // zb / z-
    [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint,0) inTextContainer:container];
    NSPoint bottom = NSMakePoint(0.0f, NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f);
    bottom.y -= NSHeight([[scrollView contentView] bounds]);
    if( bottom.y < 0.0 ){
        bottom.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:bottom];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (void)xvim_scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{ // zz / z.
    [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint,0) inTextContainer:container];
    NSPoint center = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    center.y -= NSHeight([[scrollView contentView] bounds]) / 2.0f;
    if( center.y < 0.0 ){
        center.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:center];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (void)xvim_scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{ // zt / z<CR>
    [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint,0) inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (void)xvim_scrollTo:(NSUInteger)location {
    // Update: I do not know if we really need Following block.
    //         It looks that they need it to call ensureLayoutForGlyphRange but do not know when it needed
    //         What I changed was the way calc "glyphRec". Not its using [self boundingRectForGlyphIndex] which coniders
    //         text folding when calc the rect.
    /*
	BOOL isBlankline =
		(location == [[self string] length] || isNewline([[self string] characterAtIndex:location])) &&
		(location == 0 || isNewline([[self string] characterAtIndex:location-1]));

    NSRange characterRange;
    characterRange.location = location;
    characterRange.length = isBlankline ? 0 : 1;
    
    // Must call ensureLayoutForGlyphRange: to fix a bug where it will not scroll
    // to the appropriate glyph due to non contiguous layout
    NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
    [[self layoutManager] ensureLayoutForGlyphRange:NSMakeRange(0, glyphRange.location + glyphRange.length)];
     */
    
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:location];

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

- (void)xvim_pageForward:(NSUInteger)index count:(NSUInteger)count { // C-f
	[self xvim_scroll:1.0 count:count];
}

- (void)xvim_pageBackward:(NSUInteger)index count:(NSUInteger)count { // C-b
	[self xvim_scroll:-1.0 count:count];
}

- (void)xvim_halfPageForward:(NSUInteger)index count:(NSUInteger)count { // C-d
	[self xvim_scroll:0.5 count:count];
}

- (void)xvim_halfPageBackward:(NSUInteger)index count:(NSUInteger)count { // C-u
	[self xvim_scroll:-0.5 count:count];
}

- (void)xvim_scrollPageForward:(NSUInteger)count{
    [self xvim_pageForward:self.insertionPoint count:count];
}

- (void)xvim_scrollPageBackward:(NSUInteger)count{
    [self xvim_pageBackward:self.insertionPoint count:count];
}

- (void)xvim_scrollHalfPageForward:(NSUInteger)count{
    [self xvim_halfPageForward:self.insertionPoint count:count];
}

- (void)xvim_scrollHalfPageBackward:(NSUInteger)count{
    [self xvim_halfPageBackward:self.insertionPoint count:count];
}

- (void)xvim_scrollLineForward:(NSUInteger)count{
    [self xvim_lineDown:self.insertionPoint count:count];
}

- (void)xvim_scrollLineBackward:(NSUInteger)count{
    [self xvim_lineUp:self.insertionPoint count:count];
}

#pragma mark Search
// Thanks to  http://lists.apple.com/archives/cocoa-dev/2005/Jun/msg01909.html
- (NSRange)xvim_visibleRange:(NSTextView *)tv{
    NSScrollView *sv = [tv enclosingScrollView];
    if(!sv) return NSMakeRange(0,0);
    NSLayoutManager *lm = [tv layoutManager];
    NSRect visRect = [tv visibleRect];
    
    NSPoint tco = [tv textContainerOrigin];
    visRect.origin.x -= tco.x;
    visRect.origin.y -= tco.y;
    
    NSRange glyphRange = [lm glyphRangeForBoundingRect:visRect inTextContainer:[tv textContainer]];
    NSRange charRange = [lm characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
    return charRange;
}

- (void)xvim_highlightNextSearchCandidate:(NSString *)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward{
    NSRange range = NSMakeRange(NSNotFound,0);
    if( forward ){
        range = [self.textStorage searchRegexForward:regex from:self.insertionPoint count:count option:opt];
    }else{
        range = [self.textStorage searchRegexBackward:regex from:self.insertionPoint count:count option:opt];
    }
    if( range.location != NSNotFound ){
        [self scrollRectToVisible:[self xvim_boundingRectForGlyphIndex:range.location]];
        [self showFindIndicatorForRange:range];
    }
}

- (void)xvim_highlightNextSearchCandidateForward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt{
    [self xvim_highlightNextSearchCandidate:regex count:count option:opt forward:YES];
}

- (void)xvim_highlightNextSearchCandidateBackward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt{
    [self xvim_highlightNextSearchCandidate:regex count:count option:opt forward:NO];
}

- (void)xvim_updateFoundRanges:(NSString*)pattern withOption:(MOTION_OPTION)opt{
    NSAssert( nil != pattern, @"pattern munst not be nil");
    if( !self.needsUpdateFoundRanges ){
        return;
    }
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
	if ( opt & SEARCH_CASEINSENSITIVE ){
		r_opts |= NSRegularExpressionCaseInsensitive;
	}

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:r_opts error:&error];
    if( nil != error){
        [self.foundRanges removeAllObjects];
        return;
    }
    
    // Find all the maches
    NSString* string = self.string;
    //NSTextStorage* storage = self.textStorage;
    if( string == nil ){
        return;
    }
    NSArray*  matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    [self.foundRanges setArray:matches];
    
    // Clear current highlight.
    [self xvim_clearHighlightText];
    // Add yellow highlight
    for( NSTextCheckingResult* result in self.foundRanges){
        [self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] forCharacterRange:result.range];
    }
    
    [self setNeedsUpdateFoundRanges:NO];
}

- (void)xvim_clearHighlightText{
    if( !self.needsUpdateFoundRanges ){
        return;
    }
    NSString* string = self.string;
    [self.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0,string.length)];
    // [self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[NSColor clearColor] forCharacterRange:NSMakeRange(0, string.length)];
    [self setNeedsUpdateFoundRanges:NO];
}

- (NSRange)xvim_currentWord:(MOTION_OPTION)opt{
    return [self.textStorage currentWord:self.insertionPoint count:1 option:opt|TEXTOBJECT_INNER];
}

#pragma mark Search Position
/**
 * Takes point in view and returns its index.
 * This method automatically convert the "folded index" to "real index"
 * When some characters are folded( like placeholders) the pure index for a specifix point is
 * less than real index in the string.
 **/
- (NSUInteger)xvim_glyphIndexForPoint:(NSPoint)point {
	return [[self layoutManager] glyphIndexForPoint:point inTextContainer:[self textContainer]];
}

- (NSRect)xvim_boundingRectForGlyphIndex:(NSUInteger)glyphIndex {
    NSRect glyphRect;
    if( [self.textStorage isEOF:glyphIndex] ){
        // When the index is EOF the range to specify here can not be grater than 0. If it is greater than 0 it returns (0,0) as a glyph rect.
        glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 0)  inTextContainer:[self textContainer]];
    }else{
        glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[self textContainer]];
    }
    return glyphRect;
}

/**
 *Find and return an NSArray* with the placeholders in a current line.
 * the placeholders are returned as NSValue* objects that encode NSRange structs.
 * Returns an empty NSArray if there are no placeholders on the line.
 */
-(NSArray*)xvim_placeholdersInLine:(NSUInteger)position{
    NSMutableArray* placeholders = [[NSMutableArray alloc] initWithCapacity:2];
    NSUInteger p = [self.textStorage firstOfLine:position];
    
    for(NSUInteger curPos = p; curPos < [[self xvim_string] length]; curPos++){
        NSRange retval = [(DVTCompletingTextView*)self rangeOfPlaceholderFromCharacterIndex:curPos forward:YES wrap:NO limit:50];
        if(retval.location != NSNotFound){
            curPos = retval.location + retval.length;
            [placeholders addObject:[NSValue valueWithRange:retval]];
        }
        if ([self.textStorage isLOL:curPos] || [self.textStorage isEOF:curPos]) {
            return [placeholders autorelease];
        }
    }
    
    return [placeholders autorelease];
}


#pragma mark Operations on string

- (void)xvim_deleteCharacter:(XVimPosition)pos{
    
}

- (void)xvim_deleteLine:(NSUInteger)lineNumber{
    
}

- (void)xvim_deleteLinesFrom:(NSUInteger)line1 to:(NSUInteger)line2{
    
}

- (void)xvim_deleteRestOfLine:(XVimPosition)pos{
    
}

- (void)xvim_deleteBlockFrom:(XVimPosition)pos1 to:(XVimPosition)pos2{
    
}

- (void)xvim_joinAtLine:(NSUInteger)lineNumber{
}

- (void)xvim_vimJoinAtLine:(NSUInteger)lineNumber{
    
}

#pragma mark helper methods

- (void)xvim_syncStateFromView{
    // TODO: handle block selection (if selectedRanges have multiple ranges )
    if( self.xvim_lockSyncStateFromView ){
        return;
    }
    NSRange r = [self selectedRange];
    DEBUG_LOG(@"Selected Range(TotalLen:%d): Loc:%d Len:%d", self.string.length, r.location, r.length);
    self.selectionMode = XVIM_VISUAL_NONE;
    [self xvim_moveCursor:r.location preserveColumn:NO];
    self.selectionBegin = self.insertionPoint;
}

@end


@implementation NSTextView(VimOperationPrivate)
#pragma mark Properties

- (BOOL)xvim_lockSyncStateFromView{
    id ret = [self dataForName:@"lockSyncStateFromView"];
    return nil == ret ? NO : [ret boolValue];
}

- (void)setXvim_lockSyncStateFromView:(BOOL)lock{
    [self setBool:lock forName:@"lockSyncStateFromView"];
}

/**
 * Returns start and end position of the specified motion.
 * Note that this may return NSNotFound
 **/

- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve{
    // This method only update the internal state(like self.insertionPoint)
    
    if( pos > [self xvim_string].length){
        ERROR_LOG(@"Position specified exceeds the length of the text");
        pos = [self xvim_string].length;
    }
    
    if( self.cursorMode == CURSOR_MODE_COMMAND && !(self.selectionMode == XVIM_VISUAL_BLOCK)){
        self.insertionPoint = [self.textStorage convertToValidCursorPositionForNormalMode:pos];
    }else{
        self.insertionPoint = pos;
    }
    
    if( !preserve ){
        self.preservedColumn = [self.textStorage columnNumber:self.insertionPoint];
    }
    
    DEBUG_LOG(@"New Insertion Point:%d     Preserved Column:%d", self.insertionPoint, self.preservedColumn);
}

- (void)xvim_deleteLine:(NSUInteger)lineNum{
    NSUInteger pos = [self.textStorage positionAtLineNumber:lineNum];
    if( NSNotFound == pos ){
        return;
    }
    
    if( [self.textStorage isLastLine:pos] ){
        // To delete last line we need to delete newline char before this line
        NSUInteger start = pos;
        if( pos != 0 ){
            start = pos - 1;
        }
        
        // Delete upto end of line of the last line.
        NSUInteger end = [self.textStorage endOfLine:pos];
        if( NSNotFound == end ){
            // The last line is blank-EOF line
            [self insertText:@"" replacementRange:NSMakeRange(start, end-start+1)];
        }else{
            [self insertText:@"" replacementRange:NSMakeRange(start, end-start)];
        }
    }else{
        NSUInteger end = [self.textStorage endOfLine:pos];
        NSAssert( end != NSNotFound, @"Only when it is last line it return NSNotFound");
        [self insertText:@"" replacementRange:NSMakeRange(pos, end-pos+1)]; //delete including newline
    }
}

- (void)_adjustCursorPosition{
    if( ![self.textStorage isValidCursorPosition:self.insertionPoint] ){
        NSRange placeholder = [(DVTSourceTextView*)self rangeOfPlaceholderFromCharacterIndex:self.insertionPoint forward:NO wrap:NO limit:0];
        if( placeholder.location != NSNotFound && self.insertionPoint == (placeholder.location + placeholder.length)){
            //The condition here means that just before current insertion point is a placeholder.
            //So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
            [self xvim_moveCursor:placeholder.location preserveColumn:NO];
        }else{
            [self xvim_moveCursor:self.insertionPoint-1 preserveColumn:NO];
        }
    }
    
}

/**
 * Applies internal state to underlying view (self).
 * This update self's property and applies the visual effect on it.
 * All the state need to express Vim is held by this class and
 * we use self to express it visually.
 **/
- (void)xvim_syncState{
    DEBUG_LOG(@"IP:%d", self.insertionPoint);
    self.xvim_lockSyncStateFromView = YES;
    // Reset current selection
    if( self.cursorMode == CURSOR_MODE_COMMAND ){
        [self _adjustCursorPosition];
    }
    [self dumpState];

#ifdef __XCODE5__
    [self setSelectedRanges:[self xvim_selectedRanges] affinity:NSSelectionAffinityDownstream stillSelecting:NO];
#else
    [(DVTFoldingTextStorage*)self.textStorage increaseUsingFoldedRanges];
    [self setSelectedRanges:[self xvim_selectedRanges] affinity:NSSelectionAffinityDownstream stillSelecting:NO];
    [(DVTFoldingTextStorage*)self.textStorage decreaseUsingFoldedRanges];
#endif
    [self xvim_scrollTo:self.insertionPoint];
    self.xvim_lockSyncStateFromView = NO;
}

// xvim_setSelectedRange is an internal method
// This is used when you want to call [self setSelectedRrange];
// The difference is that this checks the bounds(range can not be include EOF) and protect from Assersion
// Cursor can be on EOF but EOF can not be selected.
// It means that
//   - setSelectedRange:NSMakeRange( indexOfEOF, 0 )   is allowed
//   - setSelectedRange:NSMakeRange( indexOfEOF, 1 )   is not allowed
- (void)xvim_setSelectedRange:(NSRange)range{
    if( [self.textStorage isEOF:range.location] ){
        [self setSelectedRange:NSMakeRange(range.location,0)];
        return;
    }
    if( 0 == range.length ){
        // No need to check bounds
    }else{
        NSUInteger lastIndex = range.location + range.length - 1;
        if( [self.textStorage isEOF:lastIndex] ){
            range.length--;
        }else{
            // No need to change the selection area
        }
    }
    [self setSelectedRange:range];
    LOG_STATE();
}

- (void)dumpState{
    LOG_STATE();
}

- (NSArray*)xvim_selectedRanges{
    NSUInteger selectionStart, selectionEnd = NSNotFound;
    NSMutableArray* rangeArray = [[[NSMutableArray alloc] init] autorelease];
    // And then select new selection area
    if (self.selectionMode == XVIM_VISUAL_NONE) { // its not in selecting mode
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(self.insertionPoint,0)]];
    }
    else if( self.selectionMode == XVIM_VISUAL_CHARACTER){
        selectionStart = MIN(self.insertionPoint,self.selectionBegin);
        selectionEnd = MAX(self.insertionPoint,self.selectionBegin);
        if( [self.textStorage isEOF:selectionStart] ){
            // EOF can not be selected
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,0)]];
        }else if( [self.textStorage isEOF:selectionEnd] ){
            selectionEnd--;
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }else{
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }
    }else if(self.selectionMode == XVIM_VISUAL_LINE ){
        NSUInteger min = MIN(self.insertionPoint,self.selectionBegin);
        NSUInteger max = MAX(self.insertionPoint,self.selectionBegin);
        selectionStart = [self.textStorage beginningOfLine:min];
        selectionEnd   = [self.textStorage endOfLine:max];
        if( [self.textStorage isEOF:selectionStart] ){
            // EOF can not be selected
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,0)]];
        }else if( [self.textStorage isEOF:selectionEnd] ){
            selectionEnd--;
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }else{
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
        }
    }else if( self.selectionMode == XVIM_VISUAL_BLOCK){
        // Define the block as a rect by line and column number
        NSUInteger top    = MIN( [self.textStorage lineNumber:self.insertionPoint], [self.textStorage lineNumber:self.selectionBegin] );
        NSUInteger bottom = MAX( [self.textStorage lineNumber:self.insertionPoint], [self.textStorage lineNumber:self.selectionBegin] );
        NSUInteger left   = MIN( [self.textStorage columnNumber:self.insertionPoint], [self.textStorage columnNumber:self.selectionBegin] );
        NSUInteger right  = MAX( [self.textStorage columnNumber:self.insertionPoint], [self.textStorage columnNumber:self.selectionBegin] );
        for( NSUInteger i = 0; i < bottom-top+1 ; i++ ){
            selectionStart = [self.textStorage positionAtLineNumber:top+i column:left];
            selectionEnd = [self.textStorage positionAtLineNumber:top+i column:right];
            if( [self.textStorage isEOF:selectionStart] || [self.textStorage isEOL:selectionStart]){
                // EOF or EOL can not be selected
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,0)]]; // 0 means No selection. This information is important and used in operators like 'delete'
            }else if( [self.textStorage isEOF:selectionEnd] || [self.textStorage isEOL:selectionEnd]){
                selectionEnd--;
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
            }else{
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(selectionStart,selectionEnd-selectionStart+1)]];
            }
        }
    }
    return rangeArray;
}

- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion{
    NSRange range = NSMakeRange( NSNotFound , 0 );
    NSUInteger begin = current;
    NSUInteger end = NSNotFound;
    NSUInteger tmpPos = NSNotFound;
    
    switch (motion.motion) {
        case MOTION_NONE:
            // Do nothing
            break;
        case MOTION_FORWARD:
            end = [self.textStorage next:begin count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_BACKWARD:
            end = [self.textStorage prev:begin count:motion.count option:motion.option ];
            break;
        case MOTION_WORD_FORWARD:
            end = [self.textStorage wordsForward:begin count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_WORD_BACKWARD:
            end = [self.textStorage wordsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_FORWARD:
            end = [self.textStorage endOfWordsForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_BACKWARD:
            end = [self.textStorage endOfWordsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_LINE_FORWARD:
            end = [self.textStorage nextLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_LINE_BACKWARD:
            end = [self.textStorage prevLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_BEGINNING_OF_LINE:
            end = [self.textStorage beginningOfLine:begin];
            if( end == NSNotFound){
                end = current;
            }
            break;
        case MOTION_END_OF_LINE:
            tmpPos = [self.textStorage nextLine:begin column:0 count:motion.count-1 option:MOTION_OPTION_NONE];
            end = [self.textStorage endOfLine:tmpPos];
            if( end == NSNotFound){
                end = tmpPos;
            }
            break;
        case MOTION_SENTENCE_FORWARD:
            end = [self.textStorage sentencesForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_SENTENCE_BACKWARD:
            end = [self.textStorage sentencesBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_FORWARD:
            end = [self.textStorage paragraphsForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_BACKWARD:
            end = [self.textStorage paragraphsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_NEXT_CHARACTER:
            end = [self.textStorage nextCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            break;
        case MOTION_PREV_CHARACTER:
            end = [self.textStorage prevCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            break;
        case MOTION_TILL_NEXT_CHARACTER:
            end = [self.textStorage nextCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            if(end != NSNotFound){
                end--;
            }
            break;
        case MOTION_TILL_PREV_CHARACTER:
            end = [self.textStorage prevCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            if(end != NSNotFound){
                end++;
            }
            break;
        case MOTION_NEXT_FIRST_NONBLANK:
            end = [self.textStorage nextLine:begin column:0 count:motion.count option:motion.option];
            tmpPos = [self.textStorage nextNonblankInLine:end];
            if( NSNotFound != tmpPos ){
                end = tmpPos;
            }
            break;
        case MOTION_PREV_FIRST_NONBLANK:
            end = [self.textStorage prevLine:begin column:0 count:motion.count option:motion.option];
            tmpPos = [self.textStorage nextNonblankInLine:end];
            if( NSNotFound != tmpPos ){
                end = tmpPos;
            }
            break;
        case MOTION_FIRST_NONBLANK:
            end = [self.textStorage firstOfLineWithoutSpaces:begin];
            break;
        case MOTION_LINENUMBER:
            end = [self.textStorage positionAtLineNumber:motion.line column:self.preservedColumn];
            if( NSNotFound == end ){
                end = [self.textStorage positionAtLineNumber:[self.textStorage numberOfLines] column:self.preservedColumn];
            }
            break;
        case MOTION_PERCENT:
            end = [self.textStorage positionAtLineNumber:1 + ([self.textStorage numberOfLines]-1) * motion.count/100];
            break;
        case MOTION_NEXT_MATCHED_ITEM:
            end = [self.textStorage positionOfMatchedPair:begin];
            break;
        case MOTION_LASTLINE:
            end = [self.textStorage positionAtLineNumber:[self.textStorage numberOfLines] column:self.preservedColumn];
            break;
        case MOTION_HOME:
            end = [self.textStorage firstNonblankInLine:[self.textStorage positionAtLineNumber:[self xvim_lineNumberFromTop:motion.count]]];
            break;
        case MOTION_MIDDLE:
            end = [self.textStorage firstNonblankInLine:[self.textStorage positionAtLineNumber:[self xvim_lineNumberAtMiddle]]];
            break;
        case MOTION_BOTTOM:
            end = [self.textStorage firstNonblankInLine:[self.textStorage positionAtLineNumber:[self xvim_lineNumberFromBottom:motion.count]]];
            break;
        case MOTION_SEARCH_FORWARD:
            end = [self.textStorage searchRegexForward:motion.regex from:self.insertionPoint count:motion.count option:motion.option].location;
            break;
        case MOTION_SEARCH_BACKWARD:
            end = [self.textStorage searchRegexBackward:motion.regex from:self.insertionPoint count:motion.count option:motion.option].location;
            break;
        case TEXTOBJECT_WORD:
            range = [self.textStorage currentWord:begin count:motion.count  option:motion.option];
            break;
        case TEXTOBJECT_BRACES:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '{', '}');
            break;
        case TEXTOBJECT_PARAGRAPH:
            // Not supported
            break;
        case TEXTOBJECT_PARENTHESES:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '(', ')');
            break;
        case TEXTOBJECT_SENTENCE:
            // Not supported
            break;
        case TEXTOBJECT_ANGLEBRACKETS:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '<', '>');
            break;
        case TEXTOBJECT_SQUOTE:
            range = xv_current_quote([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '\'');
            break;
        case TEXTOBJECT_DQUOTE:
            range = xv_current_quote([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '\"');
            break;
        case TEXTOBJECT_TAG:
            // Not supported
            break;
        case TEXTOBJECT_BACKQUOTE:
            range = xv_current_quote([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '`');
            break;
        case TEXTOBJECT_SQUAREBRACKETS:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '[', ']');
            break;
        case MOTION_LINE_COLUMN:
            end = [self.textStorage positionAtLineNumber:motion.line column:motion.column];
            if( NSNotFound == end ){
                end = current;
            }
            break;
        case MOTION_POSITION:
            end = motion.position;
            break;
    }
    
    if( range.location != NSNotFound ){// This block is for TEXTOBJECT
        begin = range.location;
        if( range.length == 0 ){
            end = NSNotFound;
        }else{
            end = range.location + range.length - 1;
        }
    }
    XVimRange r = XVimMakeRange(begin, end);
    TRACE_LOG(@"range location:%u  length:%u", r.begin, r.end);
    return r;
}

- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
    if( [[self xvim_string] length] == 0 ){
        NSMakeRange(0,0); // No range
    }
    
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }
    // EOF can not be included in operation range.
    if( [self.textStorage isEOF:from] ){
        return NSMakeRange(from, 0); // from is EOF but the length is 0 means EOF will not be included in the returned range.
    }
    
    // EOF should not be included.
    // If type is exclusive we do not subtract 1 because we do it later below
    if( [self.textStorage isEOF:to] && type != CHARACTERWISE_EXCLUSIVE){
        to--; // Note that we already know that "to" is not 0 so not chekcing if its 0.
    }
    
    // At this point "from" and "to" is not EOF
    if( type == CHARACTERWISE_EXCLUSIVE ){
        // to will not be included.
        to--;
    }else if( type == CHARACTERWISE_INCLUSIVE ){
        // Nothing special
    }else if( type == LINEWISE ){
        to = [self.textStorage endOfLine:to];
        if( [self.textStorage isEOF:to] ){
            to--;
        }
        NSUInteger head = [self.textStorage firstOfLine:from];
        if( NSNotFound != head ){
            from = head;
        }
    }
	
	return NSMakeRange(from, to - from + 1); // Inclusive range
}

- (void)xvim_yankRanges:(NSArray*)ranges withType:(MOTION_TYPE)type{
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        if( type == CHARACTERWISE_EXCLUSIVE || type == CHARACTERWISE_INCLUSIVE ){
            self.lastYankedType = TEXT_TYPE_CHARACTERS;
        }else if( type == LINEWISE ){
            self.lastYankedType = TEXT_TYPE_LINES;
        }
    }else if( self.selectionMode == XVIM_VISUAL_CHARACTER){
        self.lastYankedType = TEXT_TYPE_CHARACTERS;
    }else if( self.selectionMode == XVIM_VISUAL_LINE ){
        self.lastYankedType = TEXT_TYPE_LINES;
    }else if( self.selectionMode == XVIM_VISUAL_BLOCK ){
        self.lastYankedType = TEXT_TYPE_BLOCK;
    }
    TRACE_LOG(@"YANKED TYPE:%d", self.lastYankedType);
    
    NSMutableArray* tmp = [[[NSMutableArray alloc] init] autorelease];
    for( NSValue* range in ranges ){
        if( range.rangeValue.length == 0 ){
            // Nothing to yank
            [tmp addObject:@""];
        }else{
            NSString* str = [[self.textStorage string] substringWithRange:range.rangeValue];
            [tmp addObject:str];
        }
    }
    
    // LINEWISE yank of last line (the line including EOF) is special case
    // where we treat EOF as a newline when yank
    if( self.lastYankedType == TEXT_TYPE_LINES){
        NSString* lastLine = [tmp lastObject];
        if( !isNewline([lastLine characterAtIndex:[lastLine length]-1]) ){
            [tmp addObject:@""]; // add empty dummy line
        }
    }
    self.lastYankedText = [tmp componentsJoinedByString:@"\n"];
    TRACE_LOG(@"YANKED STRING : %@", self.lastYankedText);
}

- (void)xvim_shfit:(XVimMotion*)motion right:(BOOL)right{
    if( self.insertionPoint == 0 && [[self xvim_string] length] == 0 ){
        return ;
    }
    
    NSUInteger count = 1;
    XVimPosition insertionAfterShift = self.insertionPosition;
    if( self.selectionMode == XVIM_VISUAL_NONE ){
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if( to.end == NSNotFound ){
            return;
        }
        NSRange r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:LINEWISE];
        [self xvim_setSelectedRange:r];
    }else{
        count = motion.count; // Only when its visual mode we treat caunt as repeating shifting
        // The cursor after the operation is the first line of selection and the same column of current insertion point
        NSUInteger start = [[[self xvim_selectedRanges] objectAtIndex:0] rangeValue].location;
        insertionAfterShift = XVimMakePosition( [self.textStorage lineNumber:start], insertionAfterShift.column);
        NSRange lastSelection = [[[self xvim_selectedRanges] lastObject] rangeValue];
        NSUInteger end = lastSelection.location + lastSelection.length - 1;
        [self xvim_setSelectedRange:NSMakeRange(start, end-start+1)];
    }
    
    for( NSUInteger i = 0 ; i < count ; i++ ){
        if( right ){
            [(DVTSourceTextView*)self shiftRight:self];
        }else{
            [(DVTSourceTextView*)self shiftLeft:self];
        }
    }
    [self xvim_moveCursor:[self.textStorage positionAtLineNumber:insertionAfterShift.line column:insertionAfterShift.column] preserveColumn:NO];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [self xvim_syncState];
}

- (void)xvim_indentCharacterRange:(NSRange)range{
#ifdef __USE_DVTKIT__
    if ( [self.textStorage isKindOfClass:[DVTTextStorage class]] ){
        [(DVTTextStorage*)self.textStorage indentCharacterRange:range undoManager:self.undoManager];
    }
    return;
#else
#error You must implement here
#endif
         
     NSAssert(NO, @"You must implement here if you dont use this caregory with DVTSourceTextView");
}
         
#pragma mark scrolling
// This is used by scrollBottom,Top,Center as a common method
- (void)xvim_scrollCommon_moveCursorPos:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{
    if( lineNumber != 0 ){
        NSUInteger pos = [self.textStorage positionAtLineNumber:lineNumber];
        if( NSNotFound == pos ){
            pos = [self.textStorage endOfFile];
        }
        [self xvim_moveCursor:pos preserveColumn:NO];
        [self xvim_syncState];
    }
    if( fnb ){
        NSUInteger pos = [self.textStorage firstNonblankInLine:self.insertionPoint];
        [self xvim_moveCursor:pos preserveColumn:NO];
        [self xvim_syncState];
    }
}

- (NSUInteger)xvim_lineNumberFromBottom:(NSUInteger)count { // L
    NSAssert( 0 != count , @"count starts from 1" );
    if( count > [self xvim_numberOfLinesInVisibleRect] ){
        count = [self xvim_numberOfLinesInVisibleRect];
    }
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    // This calculate the position of the bottom line and substruct height of "count" of lines to upwards
    bottom.y += [[scrollView contentView] bounds].size.height - (NSHeight(glyphRect) / 2.0f) - (NSHeight(glyphRect) * (count-1));
    return [self.textStorage lineNumber:[[scrollView documentView] characterIndexForInsertionAtPoint:bottom]];
}

- (NSUInteger)xvim_lineNumberAtMiddle{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint center = [[scrollView contentView] bounds].origin;
    center.y += [[scrollView contentView] bounds].size.height / 2;
    return [self.textStorage lineNumber:[[scrollView documentView] characterIndexForInsertionAtPoint:center]];
}

- (NSUInteger)xvim_lineNumberFromTop:(NSUInteger)count{
    NSAssert( 0 != count , @"count starts from 1" );
    if( count > [self xvim_numberOfLinesInVisibleRect] ){
        count = [self xvim_numberOfLinesInVisibleRect];
    }
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = [[scrollView contentView] bounds].origin;
    // Add height of "count" of lines to downwards
    top.y += (NSHeight(glyphRect) / 2.0f) + (NSHeight(glyphRect) * (count-1));
    return [self.textStorage lineNumber:[[scrollView documentView] characterIndexForInsertionAtPoint:top]];
}

- (NSRange)xvim_search:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward{
    NSRange ret = NSMakeRange(NSNotFound, 0);
    if( forward ){
        ret = [self.textStorage searchRegexForward:regex from:self.insertionPoint count:count option:opt];
    }else{
        ret = [self.textStorage searchRegexBackward:regex from:self.insertionPoint count:count option:opt];
    }
    return ret;
}

- (void)xvim_swapCaseForRange:(NSRange)range {
    NSString* text = [self xvim_string];
	
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

/* May be used later
- (void)hideCompletions {
	[[[self xview] completionController] hideCompletions];
}

- (void)selectNextPlaceholder {
	[[self xview] selectNextPlaceholder:self];
}

- (void)selectPreviousPlaceholder {
	[[self xview] selectPreviousPlaceholder:self];
}
 */
@end