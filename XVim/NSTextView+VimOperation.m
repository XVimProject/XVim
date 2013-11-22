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
#import "XVimUndo.h"
#import "XVimBuffer.h"
#import "XVimStringBuffer.h"

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
@property XVIM_VISUAL_MODE selectionMode;
@property BOOL selectionToEOL;
@property CURSOR_MODE cursorode;
@property(readonly) NSMutableArray* foundRanges;

// Internal properties
@property(strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
@end

@interface NSTextView(VimOperationPrivate)
@property BOOL xvim_lockSyncStateFromView;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState; // update self's properties with our variables
- (NSArray*)xvim_selectedRanges;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)xvim_indentCharacterRange:(NSRange)range;
- (NSRange)xvim_search:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward;
- (void)xvim_swapCaseForRange:(NSRange)range;
- (void)xvim_registerInsertionPointForUndo;
- (void)xvim_registerIndexForUndo:(NSUInteger)index;
@end

@implementation NSTextView (VimOperation)

#pragma mark internal helpers

- (void)_xvim_insertSpaces:(NSUInteger)count replacementRange:(NSRange)replacementRange
{
    if (count || replacementRange.length) {
        [self insertText:[NSString stringMadeOfSpaces:count] replacementRange:replacementRange];
    }
}

- (XVimRange)_xvim_selectedLines{
    if (self.selectionMode == XVIM_VISUAL_NONE) { // its not in selecting mode
        return (XVimRange){ NSNotFound, NSNotFound };
    } else {
        XVimBuffer *buffer = self.textStorage.xvim_buffer;
        NSUInteger l1 = [buffer lineNumberAtIndex:self.insertionPoint];
        NSUInteger l2 = [buffer lineNumberAtIndex:self.selectionBegin];

        return (XVimRange){ MIN(l1, l2), MAX(l1, l2) };
    }
}

- (NSRange)_xvim_selectedRange{
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        return NSMakeRange(self.insertionPoint, 0);
    }

    if (self.selectionMode == XVIM_VISUAL_CHARACTER) {
        XVimRange xvr = XVimMakeRange(self.selectionBegin, self.insertionPoint);

        if (xvr.begin > xvr.end) {
            xvr = XVimRangeSwap(xvr);
        }
        if ([self.textStorage isEOF:xvr.end]) {
            xvr.end--;
        }
        return XVimMakeNSRange(xvr);
    }

    if (self.selectionMode == XVIM_VISUAL_LINE) {
        XVimRange  lines = [self _xvim_selectedLines];
        XVimBuffer *buffer = self.textStorage.xvim_buffer;
        NSUInteger begin = [buffer indexOfLineNumber:lines.begin];
        NSUInteger end   = [buffer indexOfLineNumber:lines.end];

        end = [buffer endOfLine:end];
        if ([self.textStorage isEOF:end]) {
            end--;
        }
        return NSMakeRange(begin, end - begin + 1);
    }

    return NSMakeRange(NSNotFound, 0);
}

- (XVimSelection)_xvim_selectedBlock{
    XVimSelection result = { };

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        result.top = result.bottom = result.left = result.right = NSNotFound;
        return result;
    }

    NSTextStorage *ts = self.textStorage;
    XVimBuffer *buffer = self.textStorage.xvim_buffer;
    NSUInteger l1, c11, c12;
    NSUInteger l2, c21, c22;
    NSUInteger tabWidth = buffer.tabWidth;
    NSUInteger pos;

    pos = self.selectionBegin;
    l1  = [buffer lineNumberAtIndex:pos];
    c11 = [buffer columnOfIndex:pos];
    if (!tabWidth || [ts isEOF:pos] || [self.xvim_string characterAtIndex:pos] != '\t') {
        c12 = c11;
    } else {
        c12 = c11 + tabWidth - (c11 % tabWidth) - 1;
    }

    pos = self.insertionPoint;
    l2  = [buffer lineNumberAtIndex:pos];
    c21 = [buffer columnOfIndex:pos];
    if (!tabWidth || [ts isEOF:pos] || [self.xvim_string characterAtIndex:pos] != '\t') {
        c22 = c21;
    } else {
        c22 = c21 + tabWidth - (c21 % tabWidth) - 1;
    }

    if (l1 <= l2) {
        result.corner |= _XVIM_VISUAL_BOTTOM;
    }
    if (c11 <= c22) {
        result.corner |= _XVIM_VISUAL_RIGHT;
    }
    result.top     = MIN(l1, l2);
    result.bottom  = MAX(l1, l2);
    result.left    = MIN(c11, c21);
    result.right   = MAX(c12, c22);
    if (self.selectionToEOL) {
        result.right = XVimSelectionEOL;
    }
    return result;
}

- (void)__xvim_startYankWithType:(MOTION_TYPE)type
{
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        if (type == CHARACTERWISE_EXCLUSIVE || type == CHARACTERWISE_INCLUSIVE) {
            self.lastYankedType = TEXT_TYPE_CHARACTERS;
        } else if (type == LINEWISE) {
            self.lastYankedType = TEXT_TYPE_LINES;
        }
    } else if (self.selectionMode == XVIM_VISUAL_CHARACTER) {
        self.lastYankedType = TEXT_TYPE_CHARACTERS;
    } else if (self.selectionMode == XVIM_VISUAL_LINE) {
        self.lastYankedType = TEXT_TYPE_LINES;
    } else if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        self.lastYankedType = TEXT_TYPE_BLOCK;
    }
    TRACE_LOG(@"YANKED START WITH TYPE:%d", self.lastYankedType);
}

- (void)_xvim_yankRange:(NSRange)range withType:(MOTION_TYPE)type
{
    NSString *s;
    BOOL needsNL;

    [self __xvim_startYankWithType:type];

    needsNL = self.lastYankedType == TEXT_TYPE_LINES;
    if (range.length) {
        s = [self.xvim_string substringWithRange:range];
        if (needsNL && !isNewline([s characterAtIndex:s.length - 1])) {
            s = [s stringByAppendingString:@"\n"];
        }
    } else if (needsNL) {
        s = @"\n";
    } else {
        s = @"";
    }

    self.lastYankedText = s;
    TRACE_LOG(@"YANKED STRING : %@", s);
}

- (void)_xvim_yankSelection:(XVimSelection)sel
{
    NSTextStorage *ts = self.textStorage;
    NSString *s = self.xvim_string;
    XVimBuffer *buffer = ts.xvim_buffer;
    NSUInteger tabWidth = buffer.tabWidth;

    NSMutableString *ybuf = [[NSMutableString alloc] init];
    self.lastYankedType = TEXT_TYPE_BLOCK;

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        NSUInteger lpos = [buffer indexOfLineNumber:line column:sel.left];
        NSUInteger rpos = [buffer indexOfLineNumber:line column:sel.right];

        /* if lpos points in the middle of a tab, split it and advance lpos */
        if (![ts isEOF:lpos] && [s characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = sel.left - (sel.left % tabWidth);

            if (lcol < sel.left) {
                TRACE_LOG("lcol %ld  left %ld tab %ld", (long)lcol, (long)sel.left, (long)tabWidth);
                NSUInteger count = tabWidth - (sel.left - lcol);

                if (lpos == rpos) {
                    /* if rpos points to the same tab, truncate it to the right also */
                    count = sel.right - sel.left + 1;
                }
                [ybuf appendString:[NSString stringMadeOfSpaces:count]];
                lpos++;
            }
        }

        if (lpos <= rpos) {
            if (sel.right == XVimSelectionEOL) {
                [ybuf appendString:[s substringWithRange:NSMakeRange(lpos, rpos - lpos)]];
            } else {
                NSRange r = NSMakeRange(lpos, rpos - lpos + 1);
                NSUInteger rcol;
                BOOL mustPad = NO;

                if ([ts isEOF:rpos]) {
                    rcol = [buffer columnOfIndex:rpos];
                    mustPad = YES;
                    r.length--;
                } else {
                    unichar c = [s characterAtIndex:rpos];
                    if (isNewline(c)) {
                        rcol = [buffer columnOfIndex:rpos];
                        mustPad = YES;
                        r.length--;
                    } else if (c == '\t') {
                        rcol = [buffer columnOfIndex:rpos];
                        if (sel.right - rcol + 1 < tabWidth) {
                            mustPad = YES;
                            r.length--;
                        }
                    }
                }

                if (r.length) {
                    [ybuf appendString:[s substringWithRange:r]];
                }

                if (mustPad) {
                    [ybuf appendString:[NSString stringMadeOfSpaces:sel.right - rcol + 1]];
                }
            }
        }
        [ybuf appendString:@"\n"];
    }

    self.lastYankedText = ybuf;
    TRACE_LOG(@"YANKED STRING : %@", ybuf);
    [ybuf release];
}

- (void)_xvim_killSelection:(XVimSelection)sel
{
    NSTextStorage *ts = self.textStorage;
    NSString *s = self.xvim_string;
    XVimBuffer *buffer = ts.xvim_buffer;
    NSUInteger tabWidth = buffer.tabWidth;

    for (NSUInteger line = sel.bottom; line >= sel.top; line--) {
        NSUInteger lpos = [buffer indexOfLineNumber:line column:sel.left];
        NSUInteger rpos = [buffer indexOfLineNumber:line column:sel.right];
        NSUInteger nspaces = 0;

        if ([ts isEOF:lpos]) {
            continue;
        }

        if ([s characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = [buffer columnOfIndex:lpos];

            if (lcol < sel.left) {
                nspaces = sel.left - lcol;
                if (lpos == rpos) {
                    nspaces = tabWidth - (sel.right - sel.left + 1);
                }
            }
        }

        if ([ts isEOL:rpos]) {
            rpos--;
        } else if (lpos < rpos) {
            if ([s characterAtIndex:rpos] == '\t') {
                nspaces += tabWidth - (sel.right - [buffer columnOfIndex:rpos] + 1);
            }
        }

        NSRange   range = NSMakeRange(lpos, rpos - lpos + 1);
        NSString *repl = @"";

        if (nspaces) {
            repl = [NSString stringWithFormat:@"%*s", (int)nspaces, ""];
        }
        [self insertText:repl replacementRange:range];
    }
}


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
    return [self.textStorage.xvim_buffer columnOfIndex:self.insertionPoint];
}

- (NSUInteger)insertionLine{
    return [self.textStorage.xvim_buffer lineNumberAtIndex:self.insertionPoint];
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

- (BOOL)selectionToEOL{
    return [[self dataForName:@"selectionToEOL"] boolValue];
}

- (void)setSelectionToEOL:(BOOL)selectionToEOL{
    [self setBool:selectionToEOL forName:@"selectionToEOL"];
}

- (XVIM_VISUAL_MODE) selectionMode{
    id ret = [self dataForName:@"selectionMode"];
    return nil == ret ? XVIM_VISUAL_NONE : (XVIM_VISUAL_MODE)[ret integerValue];
}

- (void)setSelectionMode:(XVIM_VISUAL_MODE)selectionMode{
    if (self.selectionMode != selectionMode) {
        [self setInteger:selectionMode forName:@"selectionMode"];
    }
}

- (CURSOR_MODE) cursorMode{
    id ret = [self dataForName:@"cursorMode"];
    return nil == ret ? CURSOR_MODE_COMMAND : (CURSOR_MODE)[ret integerValue];
}

- (void)setCursorMode:(CURSOR_MODE)cursorMode{
    [self setInteger:cursorMode forName:@"cursorMode"];
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

- (NSString *)xvim_string
{
    return self.textStorage.xvim_buffer.string;
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

- (void)xvim_moveToIndex:(NSUInteger)index{
    [self xvim_moveCursor:index preserveColumn:NO];
    [self xvim_syncState];
}

- (void)xvim_moveToPosition:(XVimPosition)pos{
    NSUInteger index = [self.textStorage.xvim_buffer indexOfLineNumber:pos.line column:pos.column];
    [self xvim_moveToIndex:index];
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
    } else {
        switch( motion.motion ){
            case MOTION_LINE_BACKWARD:
            case MOTION_LINE_FORWARD:
            case MOTION_LASTLINE:
            case MOTION_LINENUMBER:
                // TODO: Preserve column option can be included in motion object
                if (self.selectionMode == XVIM_VISUAL_BLOCK && self.selectionToEOL) {
                    r.end = [self.textStorage.xvim_buffer endOfLine:r.end];
                }
                [self xvim_moveCursor:r.end preserveColumn:YES];
                break;
            case MOTION_END_OF_LINE:
                self.selectionToEOL = YES;
                [self xvim_moveCursor:r.end preserveColumn:NO];
                break;

            default:
                self.selectionToEOL = NO;
                [self xvim_moveCursor:r.end preserveColumn:NO];
                break;
        }
    }
    [self setNeedsDisplay:YES];
    [self xvim_syncState];
}

- (void)xvim_selectSwapEndsOnSameLine:(BOOL)onSameLine{
    if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        XVimPosition start, end;
        XVimSelection sel;
        NSUInteger pos;

        self.selectionToEOL = NO;
        sel = [self _xvim_selectedBlock];
        if (onSameLine) {
            sel.corner ^= _XVIM_VISUAL_RIGHT;
        } else {
            sel.corner ^= _XVIM_VISUAL_RIGHT | _XVIM_VISUAL_BOTTOM;
        }

        if (sel.corner & _XVIM_VISUAL_BOTTOM) {
            start.line = sel.top;
            end.line   = sel.bottom;
        } else {
            end.line   = sel.top;
            start.line = sel.bottom;
        }

        if (sel.corner & _XVIM_VISUAL_RIGHT) {
            start.column = sel.left;
            end.column   = sel.right;
        } else {
            end.column   = sel.left;
            start.column = sel.right;
        }

        pos = [self.textStorage.xvim_buffer indexOfLineNumber:start.line column:start.column];
        self.selectionBegin = pos;
        pos = [self.textStorage.xvim_buffer indexOfLineNumber:end.line column:end.column];
        [self xvim_moveCursor:pos preserveColumn:NO];
    } else if (self.selectionMode != XVIM_VISUAL_NONE) {
        NSUInteger begin = self.selectionBegin;

        self.selectionBegin = self.insertionPoint;
        [self xvim_moveCursor:begin preserveColumn:NO];
        [self setNeedsDisplay:YES];
    }
    [self xvim_syncState];
}

- (void)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank
{
    NSAssert( !(self.selectionMode == XVIM_VISUAL_NONE && motion == nil),
             @"motion must be specified if current selection mode is not visual");
    if (self.insertionPoint == 0 && [[self xvim_string] length] == 0) {
        return ;
    }
    NSUInteger newPos = NSNotFound;
    
    [self xvim_registerInsertionPointForUndo];
    
    motion.info->deleteLastLine = NO;
    if (self.selectionMode == XVIM_VISUAL_NONE) {
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
        if (yank) {
            [self _xvim_yankRange:r withType:motion.type];
        }
        [self insertText:@"" replacementRange:r];
        if (motion.type == LINEWISE) {
            newPos = [self.textStorage.xvim_buffer firstNonblankInLineAtIndex:self.insertionPoint allowEOL:YES];
        }
    } else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        BOOL toFirstNonBlank = (self.selectionMode == XVIM_VISUAL_LINE);
        NSRange range = [self _xvim_selectedRange];

        // Currently not supportin deleting EOF with selection mode.
        // This is because of the fact that NSTextView does not allow select EOF

        if (yank) {
            [self _xvim_yankRange:range withType:DEFAULT_MOTION_TYPE];
        }
        [self insertText:@"" replacementRange:range];
        if (toFirstNonBlank) {
            newPos = [self.textStorage.xvim_buffer firstNonblankInLineAtIndex:range.location allowEOL:YES];
        } else {
            newPos = range.location;
        }
    } else {
        XVimSelection sel = [self _xvim_selectedBlock];
        if (yank) {
            [self _xvim_yankSelection:sel];
        }
        [self _xvim_killSelection:sel];

        newPos = [self.textStorage.xvim_buffer indexOfLineNumber:sel.top column:sel.left];
    }

    [self.xvimDelegate textView:self didDelete:self.lastYankedText  withType:self.lastYankedType];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    if (newPos != NSNotFound) {
        [self xvim_moveCursor:newPos preserveColumn:NO];
    }
}

- (void)xvim_change:(XVimMotion*)motion{
    // We do not need to call this since this method uses xvim_delete to operate on text
    //[self xvim_registerInsertionPointForUndo]; 
    
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
        motion.option |= MOTION_OPTION_CHANGE_WORD;
    }
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_delete:motion andYank:YES];
    if( motion.info->deleteLastLine){
        [self xvim_insertNewlineAboveLine:[self.textStorage.xvim_buffer lineNumberAtIndex:self.insertionPoint]];
    }
    else if( insertNewline ){
        [self xvim_insertNewlineAboveLine:[self.textStorage.xvim_buffer lineNumberAtIndex:self.insertionPoint]];
    }else{
        
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [self xvim_syncState];
}

- (void)xvim_yank:(XVimMotion*)motion{
    NSAssert( !(self.selectionMode == XVIM_VISUAL_NONE && motion == nil), @"motion must be specified if current selection mode is not visual");
    NSUInteger newPos = NSNotFound;

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
        [self _xvim_yankRange:r withType:motion.type];
    } else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        NSRange range = [self _xvim_selectedRange];

        newPos = range.location;
        [self _xvim_yankRange:range withType:DEFAULT_MOTION_TYPE];
    } else {
        XVimSelection sel = [self _xvim_selectedBlock];

        newPos = [self.textStorage.xvim_buffer indexOfLineNumber:sel.top column:sel.left];
        [self _xvim_yankSelection:sel];
    }
    
    [self.xvimDelegate textView:self didYank:self.lastYankedText  withType:self.lastYankedType];
    if (newPos != NSNotFound) {
        [self xvim_moveCursor:newPos preserveColumn:NO];
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count{
    [self xvim_registerInsertionPointForUndo];
    
    TRACE_LOG(@"text:%@  type:%d   afterCursor:%d   count:%d", text, type, after, count);
    if( self.selectionMode != XVIM_VISUAL_NONE ){
        // FIXME: Make them not to change text from register...
        text = [NSString stringWithString:text]; // copy string because the text may be changed with folloing delete if it is from the same register...
        [self xvim_delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 1) andYank:YES];
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
            for(NSUInteger i = 0; i < count ; i++ ){
                [self insertText:text replacementRange:NSMakeRange(targetPos,0)];
            }
            insertionPointAfterPut += text.length*count - 1;
        }
    }else if( type == TEXT_TYPE_LINES ){
        if( after ){
            [self xvim_insertNewlineBelowCurrentLine];
            targetPos = self.insertionPoint;
        }else{
            targetPos= [self.textStorage.xvim_buffer startOfLine:self.insertionPoint];
        }
        insertionPointAfterPut = targetPos;
        for(NSUInteger i = 0; i < count ; i++ ){
            if( after && i == 0 ){
                // delete newline at the end. (TEXT_TYPE_LINES always have newline at the end of the text)
                NSString* t = [text  substringToIndex:text.length-1];
                [self insertText:t replacementRange:NSMakeRange(targetPos,0)];
            } else{
                [self insertText:text replacementRange:NSMakeRange(targetPos,0)];
            }
        }
    }else if( type == TEXT_TYPE_BLOCK ){
        //Forward insertion point +1 if after flag if on
        if (![self.textStorage isNewline:self.insertionPoint] && ![self.textStorage isEOF:self.insertionPoint] && after) {
            self.insertionPoint++;
        }
        insertionPointAfterPut = self.insertionPoint;
        NSUInteger insertPos = self.insertionPoint;
        NSUInteger column = [self.textStorage.xvim_buffer columnOfIndex:insertPos];
        NSUInteger startLine = [self.textStorage.xvim_buffer lineNumberAtIndex:insertPos];
        NSArray* lines = [text componentsSeparatedByString:@"\n"];
        for( NSUInteger i = 0 ; i < lines.count ; i++){
            NSString* line = [lines objectAtIndex:i];
            NSUInteger targetLine = startLine + i;
            NSUInteger head = [self.textStorage.xvim_buffer indexOfLineNumber:targetLine];
            if( NSNotFound == head ){
                NSAssert( targetLine != 0, @"This should not be happen");
                [self xvim_insertNewlineBelowLine:targetLine-1];
                head = [self.textStorage.xvim_buffer indexOfLineNumber:targetLine];
            }
            NSAssert( NSNotFound != head , @"Head of the target line must be found at this point");
            
            // Find next insertion point
            NSUInteger max = [self.textStorage.xvim_buffer numberOfColumnsInLineAtIndex:head];
            NSAssert( max != NSNotFound , @"Should not be NSNotFound");
            if( column > max ){
                // If the line does not have enough column pad it with spaces
                NSUInteger end = [self.textStorage.xvim_buffer endOfLine:head];

                [self _xvim_insertSpaces:column - max replacementRange:NSMakeRange(end, 0)];
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
            [self xvim_swapCaseForRange:r];
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
    NSUInteger end = [self.textStorage.xvim_buffer endOfLine:self.insertionPoint];
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
    NSUInteger headOfLine = [self.textStorage.xvim_buffer indexOfLineNumber:line];
    if( headOfLine == NSNotFound){
        return;
    }

    NSUInteger tail = [self.textStorage.xvim_buffer endOfLine:headOfLine];
    if( [self.textStorage isEOF:tail] ){
        // This is the last line and nothing to join
        return;
    }
    
    // Check if we need to insert space between lines.
    NSUInteger lastOfLine = [self.textStorage.xvim_buffer lastOfLine:headOfLine];
    if( lastOfLine != NSNotFound ){
        // This is not blank line so we check if the last character is space or not .
        if( ![self.textStorage isWhitespace:lastOfLine] ){
            needSpace = YES;
        }
    }

    // Search in next line for the position to join(skip white spaces in next line)
    NSUInteger posToJoin = [self.textStorage nextLine:headOfLine column:0 count:1 option:MOTION_OPTION_NONE];

    posToJoin = [self.textStorage.xvim_buffer nextNonblankInLineAtIndex:posToJoin allowEOL:YES];
    if (![self.textStorage isEOF:posToJoin] && [self.string characterAtIndex:posToJoin] == ')') {
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

- (void)xvim_join:(NSUInteger)count addSpace:(BOOL)addSpace{
    NSUInteger line;

    [self xvim_registerInsertionPointForUndo];

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        line = self.insertionLine;
    } else {
        XVimRange lines = [self _xvim_selectedLines];

        line = lines.begin;
        count = MAX(1, lines.end - lines.begin);
    }

    if (addSpace) {
        for (NSUInteger i = 0; i < count; i++) {
            [self xvim_joinAtLineNumber:line];
        }
    } else {
        XVimBuffer *buffer = self.textStorage.xvim_buffer;
        NSUInteger pos = [buffer indexOfLineNumber:line];

        for (NSUInteger i = 0; i < count; i++) {
            NSUInteger tail = [buffer endOfLine:pos];

            if (tail != NSNotFound && ![self.textStorage isEOF:tail]) {
                [self insertText:@"" replacementRange:NSMakeRange(tail, 1)];
                [self xvim_moveCursor:tail preserveColumn:NO];
            }
        }
    }

    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_filter:(XVimMotion*)motion{
    if (self.insertionPoint == 0 && [[self xvim_string] length] == 0) {
        return ;
    }
    
    NSUInteger insertionAfterFilter = self.insertionPoint;
    NSRange filterRange;
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        filterRange = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:LINEWISE];
    } else {
        XVimRange lines = [self _xvim_selectedLines];
        NSUInteger from = [self.textStorage.xvim_buffer indexOfLineNumber:lines.begin];
        NSUInteger to   = [self.textStorage.xvim_buffer indexOfLineNumber:lines.end];
        filterRange = [self xvim_getOperationRangeFrom:from To:to Type:LINEWISE];
    }

	[self xvim_indentCharacterRange:filterRange];
    [self xvim_moveCursor:insertionAfterFilter preserveColumn:NO];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)_xvim_shift:(XVimMotion*)motion right:(BOOL)right
{
    if (self.insertionPoint == 0 && [[self xvim_string] length] == 0) {
        return ;
    }

    XVimBuffer *buffer = self.textStorage.xvim_buffer;
    NSUInteger shiftWidth = buffer.indentWidth;
    NSUInteger column = 0, pos;
    XVimRange  lines;
    BOOL blockMode = NO;

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        lines = XVimMakeRange([buffer lineNumberAtIndex:to.begin], [buffer lineNumberAtIndex:to.end]);
    } else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        lines = [self _xvim_selectedLines];
        shiftWidth *= motion.count;
    } else {
        XVimSelection sel = [self _xvim_selectedBlock];

        column = sel.left;
        lines  = XVimMakeRange(sel.top, sel.bottom);
        shiftWidth *= motion.count;
        blockMode = YES;
    }

    if (blockMode) {
        pos = [buffer indexOfLineNumber:lines.begin column:column];
    } else {
        pos = [buffer indexOfLineNumber:lines.begin];
        pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
    }

    [buffer beginEditingAtIndex:pos];
    pos = [buffer shiftLines:lines column:column
                       count:shiftWidth right:right block:blockMode];
    [buffer endEditingAtIndex:pos];

    [self xvim_moveCursor:pos preserveColumn:NO];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_shiftRight:(XVimMotion*)motion{
    [self _xvim_shift:motion right:YES];
}

- (void)xvim_shiftLeft:(XVimMotion*)motion{
    [self _xvim_shift:motion right:NO];
}

- (void)xvim_insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column{
    NSUInteger pos = [self.textStorage.xvim_buffer indexOfLineNumber:line column:column];
    if( pos == NSNotFound ){
        return;
    }
    [self insertText:str replacementRange:NSMakeRange(pos,0)];
}

- (void)xvim_insertNewlineBelowLine:(NSUInteger)line{
    NSAssert( line != 0, @"line number starts from 1");
    NSUInteger pos = [self.textStorage.xvim_buffer indexOfLineNumber:line];
    if( NSNotFound == pos ){
        return;
    }
    pos = [self.textStorage.xvim_buffer endOfLine:pos];
    [self insertText:@"\n" replacementRange:NSMakeRange(pos ,0)];
    [self xvim_moveCursor:pos+1 preserveColumn:NO];
    [self xvim_syncState];
}

- (void)xvim_insertNewlineBelowCurrentLine{
    [self xvim_insertNewlineBelowLine:[self.textStorage.xvim_buffer lineNumberAtIndex:self.insertionPoint]];
}

- (void)xvim_insertNewlineBelowCurrentLineWithIndent{
    NSUInteger tail = [self.textStorage.xvim_buffer endOfLine:self.insertionPoint];
    [self setSelectedRange:NSMakeRange(tail,0)];
    [self insertNewline:self];
}

- (void)xvim_insertNewlineAboveLine:(NSUInteger)line{
    NSAssert( line != 0, @"line number starts from 1");
    NSUInteger pos = [self.textStorage.xvim_buffer indexOfLineNumber:line];
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

- (void)xvim_insertNewlineAboveCurrentLine{
    [self xvim_insertNewlineAboveLine:[self.textStorage.xvim_buffer lineNumberAtIndex:self.insertionPoint]];
}

- (void)xvim_insertNewlineAboveCurrentLineWithIndent{
    NSUInteger head = [self.textStorage.xvim_buffer firstOfLine:self.insertionPoint];
    if( NSNotFound == head ){
        head = self.insertionPoint;
    }
    if( 0 != head ){
        [self setSelectedRange:NSMakeRange(head-1,0)];
        [self insertNewline:self];
    }else{
        [self setSelectedRange:NSMakeRange(head,0)];
        [self insertNewline:self];
        [self setSelectedRange:NSMakeRange(0,0)];
    }
}

- (void)xvim_insertNewlineAboveAndInsertWithIndent{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_insertNewlineAboveCurrentLineWithIndent];
}

- (void)xvim_insertNewlineBelowAndInsertWithIndent{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_insertNewlineBelowCurrentLineWithIndent];
}

- (void)xvim_insert:(XVimInsertionPoint)mode blockColumn:(NSUInteger *)column blockLines:(XVimRange *)lines{
    NSTextStorage *ts = self.textStorage;
    XVimBuffer *buffer = ts.xvim_buffer;

    if (column) *column = NSNotFound;
    if (lines)  *lines  = XVimMakeRange(NSNotFound, NSNotFound);

    if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        XVimSelection sel = [self _xvim_selectedBlock];

        if (lines) *lines = XVimMakeRange(sel.top, sel.bottom);
        switch (mode) {
            case XVIM_INSERT_BLOCK_KILL_EOL:
                sel.right = XVimSelectionEOL;
                /* fallthrough */
            case XVIM_INSERT_BLOCK_KILL:
                [self _xvim_yankSelection:sel];
                [self _xvim_killSelection:sel];
                /* falltrhough */
            case XVIM_INSERT_DEFAULT:
                self.insertionPoint = [buffer indexOfLineNumber:sel.top column:sel.left];
                if (column) *column = sel.left;
                break;
            case XVIM_INSERT_APPEND:
                if (sel.right != XVimSelectionEOL) {
                    sel.right++;
                }
                self.insertionPoint = [buffer indexOfLineNumber:sel.top column:sel.right];
                if (column) *column = sel.right;
                break;
            default:
                NSAssert(false, @"unreachable");
                break;
        }
    } else if (mode != XVIM_INSERT_DEFAULT) {
        NSUInteger pos = self.insertionPoint;
        switch (mode) {
            case XVIM_INSERT_APPEND_EOL:
                self.insertionPoint = [buffer endOfLine:pos];
                break;
            case XVIM_INSERT_APPEND:
                NSAssert(self.cursorMode == CURSOR_MODE_COMMAND, @"self.cursorMode shoud be CURSOR_MODE_COMMAND");
                if (![ts isEOF:pos] && ![ts isNewline:pos]){
                    self.insertionPoint = pos + 1;
                }
                break;
            case XVIM_INSERT_BEFORE_FIRST_NONBLANK:
                self.insertionPoint = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
                break;
            default:
                NSAssert(false, @"unreachable");
        }
    }
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [self xvim_syncState];
}

- (void)xvim_overwriteCharacter:(unichar)c{
    if (self.insertionPoint >= self.textStorage.length) {
        // Should not happen.
        return;
    }
    [self insertText:[NSString stringWithFormat:@"%c",c] replacementRange:NSMakeRange(self.insertionPoint,1)];
    return;
}

- (BOOL)xvim_incrementNumber:(int64_t)offset
{
    NSUInteger ip = self.insertionPoint;

    ip = [self.textStorage.xvim_buffer incrementNumberAtIndex:ip by:offset];
    if (ip == NSNotFound) {
        return NO;
    }
    [self xvim_moveCursor:ip preserveColumn:NO];
    return YES;
}

- (void)xvim_blockInsertFixupWithText:(NSString *)text mode:(XVimInsertionPoint)mode
                                count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines
{
    NSMutableString *buf = nil;
    NSTextStorage *ts;
    NSUInteger tabWidth;
    XVimBuffer *buffer;

    if (count == 0 || lines.begin > lines.end || text.length == 0) {
        return;
    }
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return;
    }
    if (count > 1) {
        buf = [[NSMutableString alloc] initWithCapacity:text.length * count];
        for (NSUInteger i = 0; i < count; i++) {
            [buf appendString:text];
        }
        text = buf;
    }

    ts = self.textStorage;
    buffer = ts.xvim_buffer;
    tabWidth = buffer.tabWidth;

    for (NSUInteger line = lines.begin; line <= lines.end; line++) {
        NSUInteger pos = [buffer indexOfLineNumber:line column:column];

        if (column != XVimSelectionEOL && [ts isEOL:pos]) {
            if ([buffer columnOfIndex:pos] < column) {
                if (mode != XVIM_INSERT_APPEND) {
                    continue;
                }
                [self _xvim_insertSpaces:column - [buffer columnOfIndex:pos] replacementRange:NSMakeRange(pos, 0)];
            }
        }
        if (tabWidth && [self.xvim_string characterAtIndex:pos] == '\t') {
            NSUInteger col = [buffer columnOfIndex:pos];

            if (col < column) {
                [self _xvim_insertSpaces:tabWidth - (col % tabWidth) replacementRange:NSMakeRange(pos, 1)];
                pos += column - col;
            }
        }
        [self insertText:text replacementRange:NSMakeRange(pos, 0)];
    }

    [buf release];
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
    
    NSRange characterRange = [self.textStorage.xvim_buffer indexRangeForLines:NSMakeRange(line1, line2 - line1 + 1)];
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
        [self.xvim_view scrollTo:range.location];
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
 *Find and return an NSArray* with the placeholders in a current line.
 * the placeholders are returned as NSValue* objects that encode NSRange structs.
 * Returns an empty NSArray if there are no placeholders on the line.
 */
-(NSArray*)xvim_placeholdersInLine:(NSUInteger)position{
    NSMutableArray* placeholders = [[NSMutableArray alloc] initWithCapacity:2];
    NSUInteger p = [self.textStorage.xvim_buffer firstOfLine:position];
    
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
        self.preservedColumn = [self.textStorage.xvim_buffer columnOfIndex:self.insertionPoint];
    }
    
    DEBUG_LOG(@"New Insertion Point:%d     Preserved Column:%d", self.insertionPoint, self.preservedColumn);
}

- (void)_adjustCursorPosition{
    if( ![self.textStorage isValidCursorPosition:self.insertionPoint] ){
        NSRange placeholder = [(DVTSourceTextView*)self rangeOfPlaceholderFromCharacterIndex:self.insertionPoint forward:NO wrap:NO limit:0];
        if( placeholder.location != NSNotFound && self.insertionPoint == (placeholder.location + placeholder.length)){
            //The condition here means that just before current insertion point is a placeholder.
            //So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
            [self xvim_moveCursor:placeholder.location preserveColumn:YES];
        }else{
            [self xvim_moveCursor:self.insertionPoint-1 preserveColumn:YES];
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
    [self.xvim_view scrollTo:self.insertionPoint];
    self.xvim_lockSyncStateFromView = NO;
}

- (void)dumpState{
    LOG_STATE();
}

- (NSArray*)xvim_selectedRanges{
    if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        return [NSArray arrayWithObject:[NSValue valueWithRange:[self _xvim_selectedRange]]];
    }

    NSMutableArray *rangeArray = [[[NSMutableArray alloc] init] autorelease];
    NSTextStorage  *ts = self.textStorage;
    XVimBuffer     *buffer = ts.xvim_buffer;
    XVimSelection sel = [self _xvim_selectedBlock];

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        NSUInteger begin = [buffer indexOfLineNumber:line column:sel.left];
        NSUInteger end   = [buffer indexOfLineNumber:line column:sel.right];

        if ([ts isEOF:begin]) {
            continue;
        }
        if ([ts isEOF:end]){
            end--;
        } else if (sel.right != XVimSelectionEOL && [ts isEOL:end]) {
            end--;
        }
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(begin, end - begin + 1)]];
    }
    return rangeArray;
}

- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion{
    NSRange range = NSMakeRange( NSNotFound , 0 );
    NSUInteger begin = current;
    NSUInteger end = NSNotFound;
    NSUInteger tmpPos = NSNotFound;
    NSUInteger start = NSNotFound;
    NSTextStorage *ts = self.textStorage;
    XVimBuffer *buffer = ts.xvim_buffer;
    XVimView *xview = self.xvim_view;

    switch (motion.motion) {
        case MOTION_NONE:
            // Do nothing
            break;
        case MOTION_FORWARD:
            end = [ts next:begin count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_BACKWARD:
            end = [ts prev:begin count:motion.count option:motion.option ];
            break;
        case MOTION_WORD_FORWARD:
            end = [ts wordsForward:begin count:motion.count option:motion.option info:motion.info];
            break;
        case MOTION_WORD_BACKWARD:
            end = [ts wordsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_FORWARD:
            end = [ts endOfWordsForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_BACKWARD:
            end = [ts endOfWordsBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_LINE_FORWARD:
            end = [ts nextLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_LINE_BACKWARD:
            end = [ts prevLine:begin column:self.preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_BEGINNING_OF_LINE:
            end = [ts.xvim_buffer startOfLine:begin];
            if( end == NSNotFound){
                end = current;
            }
            break;
        case MOTION_END_OF_LINE:
            tmpPos = [ts nextLine:begin column:0 count:motion.count-1 option:MOTION_OPTION_NONE];
            end = [ts.xvim_buffer endOfLine:tmpPos];
            if( end == NSNotFound){
                end = tmpPos;
            }
            break;
        case MOTION_SENTENCE_FORWARD:
            end = [ts sentencesForward:begin count:motion.count option:motion.option];
            break;
        case MOTION_SENTENCE_BACKWARD:
            end = [ts sentencesBackward:begin count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_FORWARD:
            end = [ts moveFromIndex:begin paragraphs:motion.scount option:motion.option];
            break;
        case MOTION_PARAGRAPH_BACKWARD:
            end = [ts moveFromIndex:begin paragraphs:-motion.scount option:motion.option];
            break;
        case MOTION_NEXT_CHARACTER:
            end = [ts nextCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            break;
        case MOTION_PREV_CHARACTER:
            end = [ts prevCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            break;
        case MOTION_TILL_NEXT_CHARACTER:
            end = [ts nextCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            if(end != NSNotFound){
                end--;
            }
            break;
        case MOTION_TILL_PREV_CHARACTER:
            end = [ts prevCharacterInLine:begin count:motion.count character:motion.character option:MOTION_OPTION_NONE];
            if(end != NSNotFound){
                end++;
            }
            break;
        case MOTION_NEXT_FIRST_NONBLANK:
            end = [ts nextLine:begin column:0 count:motion.count option:motion.option];
            tmpPos = [ts.xvim_buffer nextNonblankInLineAtIndex:end allowEOL:NO];
            if( NSNotFound != tmpPos ){
                end = tmpPos;
            }
            break;
        case MOTION_PREV_FIRST_NONBLANK:
            end = [ts prevLine:begin column:0 count:motion.count option:motion.option];
            tmpPos = [ts.xvim_buffer nextNonblankInLineAtIndex:end allowEOL:NO];
            if( NSNotFound != tmpPos ){
                end = tmpPos;
            }
            break;
        case MOTION_FIRST_NONBLANK:
            end = [ts.xvim_buffer firstNonblankInLineAtIndex:begin allowEOL:NO];
            break;
        case MOTION_LINENUMBER:
            end = [ts.xvim_buffer indexOfLineNumber:motion.line column:self.preservedColumn];
            if( NSNotFound == end ){
                end = [buffer indexOfLineNumber:[buffer numberOfLines] column:self.preservedColumn];
            }
            break;
        case MOTION_PERCENT:
            end = [buffer indexOfLineNumber:1 + ([buffer numberOfLines]-1) * motion.count/100];
            break;
        case MOTION_NEXT_MATCHED_ITEM:
            end = [ts positionOfMatchedPair:begin];
            break;
        case MOTION_LASTLINE:
            end = [buffer indexOfLineNumber:[buffer numberOfLines] column:self.preservedColumn];
            break;
        case MOTION_HOME:
            tmpPos = [xview lineNumberInScrollView:0.0 offset:motion.scount - 1];
            end    = [buffer firstNonblankInLineAtIndex:[buffer indexOfLineNumber:tmpPos] allowEOL:YES];
            break;
        case MOTION_MIDDLE:
            tmpPos = [xview lineNumberInScrollView:0.5 offset:0];
            end    = [buffer firstNonblankInLineAtIndex:[buffer indexOfLineNumber:tmpPos] allowEOL:YES];
            break;
        case MOTION_BOTTOM:
            tmpPos = [xview lineNumberInScrollView:1.0 offset:1 - motion.scount];
            end    = [buffer firstNonblankInLineAtIndex:[buffer indexOfLineNumber:tmpPos] allowEOL:YES];
            break;
        case MOTION_SEARCH_FORWARD:
            end = [ts searchRegexForward:motion.regex from:self.insertionPoint count:motion.count option:motion.option].location;
            break;
        case MOTION_SEARCH_BACKWARD:
            end = [ts searchRegexBackward:motion.regex from:self.insertionPoint count:motion.count option:motion.option].location;
            break;
        case TEXTOBJECT_WORD:
            range = [ts currentWord:begin count:motion.count  option:motion.option];
            break;
        case TEXTOBJECT_BRACES:
            range = xv_current_block([self xvim_string], current, motion.count, !(motion.option & TEXTOBJECT_INNER), '{', '}');
            break;
        case TEXTOBJECT_PARAGRAPH:
            // Not supported
            start = [ts moveFromIndex:self.insertionPoint paragraphs:-1 option:MOPT_PARA_BOUND_BLANKLINE];
            end   = [ts moveFromIndex:self.insertionPoint paragraphs:motion.scount option:MOPT_PARA_BOUND_BLANKLINE];
            range = NSMakeRange(start, end - start);
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
            end = [buffer indexOfLineNumber:motion.line column:motion.column];
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
        to = [self.textStorage.xvim_buffer endOfLine:to];
        if( [self.textStorage isEOF:to] ){
            to--;
        }
        NSUInteger head = [self.textStorage.xvim_buffer firstOfLine:from];
        if( NSNotFound != head ){
            from = head;
        }
    }
	
	return NSMakeRange(from, to - from + 1); // Inclusive range
}

- (void)xvim_indentCharacterRange:(NSRange)range{
#ifdef __USE_DVTKIT__
#ifdef __XCODE5__
    if ( [self.textStorage isKindOfClass:[DVTTextStorage class]] ){
        [(DVTTextStorage*)self.textStorage indentCharacterRange:range undoManager:self.undoManager];
    }
    return;
#else
    if ( [self.textStorage isKindOfClass:[DVTSourceTextStorage class]] ){
        [(DVTSourceTextStorage*)self.textStorage indentCharacterRange:range undoManager:self.undoManager];
    }
    return;
#endif
#else
#error You must implement here
#endif
         
     NSAssert(NO, @"You must implement here if you dont use this caregory with DVTSourceTextView");
}
         
#pragma mark scrolling

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
    [self xvim_registerInsertionPointForUndo];
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
    [substring release];
}

- (void)xvim_registerIndexForUndo:(NSUInteger)index
{
    XVimUndoOperation *op = [[XVimUndoOperation alloc] initWithIndex:index];
    [op registerForBuffer:self.textStorage.xvim_buffer];
    [op release];
}

- (void)xvim_registerInsertionPointForUndo
{
    [self xvim_registerIndexForUndo:self.insertionPoint];
}

@end
