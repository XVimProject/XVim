//
//  XVimBuffer.m
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import <objc/runtime.h>
#import "XVimStringBuffer.h"
#import "XVimBuffer.h"
#import "XVimView.h"
#import "XVimUndo.h"
#import "XVimTextStoring.h"
#import "NSString+VimHelper.h"
#import "Logger.h"
#import "NSCharacterSet+XVimAdditions.h"

static char const * const XVIM_KEY_BUFFER = "xvim_buffer";

@implementation NSTextStorage (XVimBuffer)

- (XVimBuffer *)xvim_buffer
{
    return objc_getAssociatedObject(self, XVIM_KEY_BUFFER);
}

@end

@implementation NSDocument (XVimBuffer)

- (XVimBuffer *)xvim_buffer
{
    return objc_getAssociatedObject(self, XVIM_KEY_BUFFER);
}

@end

@implementation XVimBuffer {
    NSDocument    *__unsafe_unretained _document;
    NSTextStorage *__unsafe_unretained _textStorage;
    XVimUndoOperation *_curOp;
    NSUInteger         _editCount;
    NSString          *_lineEnding;

    struct {
        unsigned has_xvim_string : 1;
        unsigned has_xvim_numberOfLines : 1;
        unsigned has_xvim_tabWidth : 1;
        unsigned has_xvim_indentWidth : 1;
        unsigned has_xvim_indexRangeForLineNumber : 1;
        unsigned has_xvim_indexRangeForLines : 1;
        unsigned has_xvim_lineNumberAtIndex : 1;
    } _flags;
}
@synthesize document = _document;
@synthesize textStorage = _textStorage;

- (NSUndoManager *)undoManager
{
    return _document.undoManager;
}

- (instancetype)initWithDocument:(NSDocument *)document
                     textStorage:(NSTextStorage *)textStorage
{
    if ((self = [super init])) {
        _document    = document;
        _textStorage = textStorage;
        objc_setAssociatedObject(document, XVIM_KEY_BUFFER, self, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(textStorage, XVIM_KEY_BUFFER, self, OBJC_ASSOCIATION_RETAIN);

        DEBUG_LOG("Buffer %p created for %@, backed by %@", self, document, textStorage);

        if ([_textStorage conformsToProtocol:@protocol(XVimTextStoring)]) {
#define CHECK(k, sel)  _flags.has_xvim_##k = (bool)[_textStorage respondsToSelector:sel]
            CHECK(string, @selector(xvim_string));
            CHECK(numberOfLines, @selector(xvim_numberOfLines));
            CHECK(tabWidth, @selector(xvim_tabWidth));
            CHECK(indentWidth, @selector(xvim_indentWidth));
            CHECK(indexRangeForLineNumber, @selector(xvim_indexRangeForLineNumber:newLineLength:));
            CHECK(indexRangeForLines, @selector(xvim_indexRangeForLines:));
            CHECK(lineNumberAtIndex, @selector(xvim_lineNumberAtIndex:));
#undef CHECK
        }
    }
    return self;
}

- (void)dealloc
{
    DEBUG_LOG("Buffer %p destroyed", self);

    [_curOp release];
    [super dealloc];
}

+ (XVimBuffer *)makeBufferForDocument:(NSDocument *)document
                          textStorage:(NSTextStorage *)textStorage
{
    return [[[[self class] alloc] initWithDocument:document textStorage:textStorage] autorelease];
}

#pragma mark Properties
#define _XVimTextStorage  ((NSTextStorage<XVimTextStoring> *)_textStorage)

- (NSString *)string
{
    if (_flags.has_xvim_string) {
        return _XVimTextStorage.xvim_string;
    }
    return _textStorage.string;
}

- (NSString *)lineEnding
{
    if (!_lineEnding) {
        NSUInteger nlLen;
        NSRange r;

        r = [self indexRangeForLineAtIndex:0 newLineLength:&nlLen];
        if (nlLen == 2) {
            _lineEnding = @"\r\n";
        } else if (nlLen == 1) {
            unichar c = [self.string characterAtIndex:NSMaxRange(r)];
            if (c == '\n') {
                _lineEnding = @"\n";
            } else if (c == '\r') {
                _lineEnding = @"\r";
            } else {
                // WTF??
                return @"\n";
            }
        } else {
            // FIXME: use the setting
            return @"\n";
        }
    }
    return _lineEnding;
}

- (NSUInteger)numberOfLines
{
    if (_flags.has_xvim_numberOfLines) {
        return _XVimTextStorage.xvim_numberOfLines;
    }
    return [self lineNumberAtIndex:self.length];
}

- (NSUInteger)length
{
    return _textStorage.length;
}

- (NSUInteger)tabWidth
{
    if (_flags.has_xvim_tabWidth) {
        return _XVimTextStorage.xvim_tabWidth;
    }
    return 8;
}

- (NSUInteger)indentWidth
{
    if (_flags.has_xvim_indentWidth) {
        return _XVimTextStorage.xvim_indentWidth;
    }
    return 8;
}

#pragma mark Specific positions of the index within the line

NS_INLINE NSUInteger _addClamp(NSUInteger a, NSInteger b, NSUInteger min, NSUInteger max)
{
#if DEBUG
    NSCAssert(min <= a && a <= max, @"invalid parameter to _addClamp");
#endif
    if (b < 0 && (NSInteger)a + b <= min) {
        return min;
    }
    if (b > 0 && a + (NSUInteger)b > max) {
        return max;
    }
    return (NSUInteger)((NSInteger)a + b);
}

- (BOOL)isIndexOnLastLine:(NSUInteger)index
{
    return [self endOfLine:index] == self.length;
}

- (BOOL)isIndexAtStartOfLine:(NSUInteger)index
{
    if (index == 0) {
        return YES;
    }
    if (!isNewline([self.string characterAtIndex:index - 1])) {
        return NO;
    }
    if (index >= self.length || !isNewline([self.string characterAtIndex:index])) {
        return YES;
    }
    return [self startOfLine:index] == index;
}

- (BOOL)isIndexAtEndOfLine:(NSUInteger)index
{
    return index >= self.length || isNewline([self.string characterAtIndex:index]);
}

- (BOOL)isNormalCursorPositionValidAtIndex:(NSUInteger)index
{
    NSRange range = [self indexRangeForLineAtIndex:index newLineLength:NULL];

    return range.length == 0 || index < NSMaxRange(range);
}

#pragma mark Converting between Indexes and Line Numbers

- (NSRange)indexRangeForLineNumber:(NSUInteger)num newLineLength:(NSUInteger *)newLineLength
{
    NSAssert(num > 0, @"line number starts at 1");

    if (_flags.has_xvim_indexRangeForLineNumber) {
        return [_XVimTextStorage xvim_indexRangeForLineNumber:num newLineLength:newLineLength];
    }

    // TODO: we may need to keep track line number and position by hooking insertText: method.
    // FIXME: this code is actually never called in XVim for XCode, it probably has bugs, it's not tested

    NSString  *string = self.string;
    NSUInteger length = self.length;
    NSUInteger lineNum = 0, end = 0, pos, contentsEnd;

    do {
        pos = end;
        [string getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(end, 0)];
        lineNum++;
        if (lineNum == num) {
            if (newLineLength) *newLineLength = end - contentsEnd;
            return NSMakeRange(pos, contentsEnd - pos);
        }
    } while (end < length);

    if (newLineLength) *newLineLength = 0;

    // we have a last empty line after \n
    if (contentsEnd < end) {
        lineNum++;
        if (lineNum == num) {
            return NSMakeRange(end, 0);
        }
    }

    return NSMakeRange(NSNotFound, 0);
}

- (NSRange)indexRangeForLines:(NSRange)range
{
    NSAssert(range.location > 0, @"line number starts at 1");

    if (_flags.has_xvim_indexRangeForLines) {
        return [_XVimTextStorage xvim_indexRangeForLines:range];
    }

    // TODO: we may need to keep track line number and position by hooking insertText: method.
    // FIXME: this code is actually never called in XVim for XCode, it probably has bugs, it's not tested
    NSString  *string = self.string;
    NSUInteger length = self.length, start = 0;
    NSUInteger lineNum = 0, end = 0, contentsEnd;

    do {
        [string getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(end, 0)];
        lineNum++;
        if (lineNum == range.location) {
            start = end;
        }
        if (lineNum == NSMaxRange(range)) {
            return NSMakeRange(start, end - start);
        }
    } while (end < length);

    // we have a last empty line after \n
    if (contentsEnd < end) {
        lineNum++;
        if (lineNum == range.location) {
            start = end;
        }
        if (lineNum == NSMaxRange(range)) {
            return NSMakeRange(start, end - start);
        }
    }

    return NSMakeRange(0, length);
}

- (NSRange)indexRangeForLineAtIndex:(NSUInteger)index newLineLength:(NSUInteger *)newLineLength
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSString *string = self.string;
    NSUInteger len = self.length;
    NSUInteger end, contentEnd;

    if (index > len) {
        index = len;
    }

    [string getLineStart:&index end:&end contentsEnd:&contentEnd forRange:NSMakeRange(index, 0)];
    if (newLineLength) *newLineLength = end - contentEnd;
    return NSMakeRange(index, contentEnd - index);
}

- (NSUInteger)indexOfLineNumber:(NSUInteger)num
{
    NSAssert(num > 0, @"line number start at 1");
    if (num == 1) {
        return 0;
    }
    return [self indexRangeForLineNumber:num newLineLength:NULL].location;
}

- (NSUInteger)lineNumberAtIndex:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);

    if (_flags.has_xvim_lineNumberAtIndex) {
        return [_XVimTextStorage xvim_lineNumberAtIndex:index];
    }

    NSString *string = self.string;
    NSUInteger len = self.length;
    NSUInteger num = 1, pos = 0;

    if (index > len) {
        index = len;
    }

    do {
        num++;
        if (index == pos) {
            return num;
        }
        [string getLineStart:NULL end:&pos contentsEnd:NULL forRange:NSMakeRange(pos, 0)];
    } while (pos < index);

    return num;
}


#pragma mark Converting between Indexes and Line Numbers + Columns

static NSUInteger xvim_sb_count_columns(xvim_string_buffer_t *sb, NSUInteger tabWidth)
{
    NSUInteger col = 0;

    if (!xvim_sb_at_end(sb)) {
        do {
            if (xvim_sb_peek(sb) == '\t') {
                col += tabWidth;
                if (tabWidth) col -= col % tabWidth;
            } else {
                col++;
            }
        } while (xvim_sb_next(sb));
    }

    return col;
}

- (NSUInteger)columnOfIndex:(NSUInteger)index
{
    NSRange range = [self indexRangeForLineAtIndex:index newLineLength:NULL];
    xvim_string_buffer_t sb;

    if (index < NSMaxRange(range)) {
        range.length = index - range.location;
    }
    if (range.length == 0) {
        return 0;
    }

    xvim_sb_init_range(&sb, self.string, range);
    return xvim_sb_count_columns(&sb, self.tabWidth);
}

- (XVimPosition)positionOfIndex:(NSUInteger)index
{
    return XVimMakePosition([self lineNumberAtIndex:index], [self columnOfIndex:index]);
}

- (NSUInteger)numberOfColumnsInLineAtIndex:(NSUInteger)index
{
    NSRange range = [self indexRangeForLineAtIndex:index newLineLength:NULL];
    xvim_string_buffer_t sb;

    xvim_sb_init_range(&sb, self.string, range);
    return xvim_sb_count_columns(&sb, self.tabWidth);
}

- (NSUInteger)_indexOfLineAtIndex:(NSUInteger)index column:(NSUInteger)column
{
    if (column == 0) {
        return index;
    }

    NSRange    range = [self indexRangeForLineAtIndex:index newLineLength:NULL];
    NSUInteger tabWidth = self.tabWidth;
    NSUInteger col = 0;
    xvim_string_buffer_t sb;

    xvim_sb_init_range(&sb, self.string, range);
    do {
        if (xvim_sb_peek(&sb) == '\t') {
            col += tabWidth;
            if (tabWidth) col -= col % tabWidth;
        } else {
            col++;
        }
        if (col > column) {
            return xvim_sb_index(&sb);
        }
    } while (xvim_sb_next(&sb) && col < column);

    return xvim_sb_index(&sb);
}

- (NSUInteger)indexOfLineAtIndex:(NSUInteger)index column:(NSUInteger)column
{
    return [self _indexOfLineAtIndex:[self startOfLine:index] column:column];
}

- (NSUInteger)indexOfLineNumber:(NSUInteger)num column:(NSUInteger)column
{
	NSUInteger index = [self indexOfLineNumber:num];

    if (column == 0 || index == NSNotFound) {
        return index;
    }

    return [self _indexOfLineAtIndex:index column:column];
}

#pragma mark Motion support functions

- (NSUInteger)indexOfCharMotion:(NSInteger)scount index:(NSUInteger)index options:(XVimMotionOptions)options
{
    NSUInteger nlLen, max;
    NSRange range;

    NSAssert((options & ~MOPT_NOWRAP) == 0, @"unhandled options passed");

    if (scount == 0) {
        return index;
    }

    if (options & MOPT_NOWRAP) {
        range = [self indexRangeForLineAtIndex:index newLineLength:&nlLen];
        return _addClamp(index, scount, range.location, NSMaxRange(range));
    }

    while (scount > 0) {
        range = [self indexRangeForLineAtIndex:index newLineLength:&nlLen];
        max   = NSMaxRange(range);
        if (index + (NSUInteger)scount > max) {
            scount -= max - index + 1;
            index = max + nlLen;
        } else {
            return index + (NSUInteger)scount;
        }
    }

    while (scount < 0) {
        range  = [self indexRangeForLineAtIndex:index - 1 newLineLength:&nlLen];
        max    = NSMaxRange(range);
        if (index > max) {
            // if we're just past the EOL skip it back
            scount++;
            index = max;
        }
        if ((index - range.location) >= (NSUInteger)-scount) {
            return (NSUInteger)((NSInteger)index + scount);
        }
        scount += index - range.location;
        index   = range.location;
    }

    return index;
}

- (NSUInteger)indexOfLineMotion:(NSInteger)scount index:(NSUInteger)index column:(NSUInteger)column;
{
    if (scount) {
        NSUInteger line = [self lineNumberAtIndex:index];

        line  = _addClamp(line, scount, 1, self.numberOfLines);
        index = [self indexOfLineNumber:line];
    }

    return [self _indexOfLineAtIndex:index column:column];
}

#pragma mark Searching particular positions on the current line

- (NSUInteger)startOfLine:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSString *string = self.string;
    NSUInteger len = self.length;

    if (index > len) {
        index = len;
    }
    [string getLineStart:&index end:NULL contentsEnd:NULL forRange:NSMakeRange(index, 0)];
    return index;
}

- (NSUInteger)firstOfLine:(NSUInteger)index
{
    NSUInteger pos = [self startOfLine:index];

    if (pos == index && isNewline([self.string characterAtIndex:pos])) {
        return NSNotFound;
    }
    return pos;
}

- (NSUInteger)endOfLine:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSString *string = self.string;
    NSUInteger len = self.length;

    if (index > len) {
        index = len;
    }
    [string getLineStart:NULL end:NULL contentsEnd:&index forRange:NSMakeRange(index, 0)];
    return index;
}

- (NSUInteger)lastOfLine:(NSUInteger)index
{
    NSUInteger pos = [self endOfLine:index];

    if (pos <= index && (pos == 0 || isNewline([self.string characterAtIndex:pos - 1]))) {
        return NSNotFound;
    }
    return pos - 1;
}

- (NSUInteger)nextNonblankInLineAtIndex:(NSUInteger)index allowEOL:(BOOL)allowEOL
{
    NSString *s = self.string;
    xvim_string_buffer_t sb;
    unichar c;

    ASSERT_VALID_RANGE_WITH_EOF(index);

    xvim_sb_init(&sb, s, index, index, s.length);
    xvim_sb_skip_forward(&sb, [NSCharacterSet whitespaceCharacterSet]);
    c = xvim_sb_peek(&sb);

    if (!allowEOL && (c == XVimInvalidChar || isNewline(c))) {
        return NSNotFound;
    }
    return xvim_sb_index(&sb);
}

- (NSUInteger)firstNonblankInLineAtIndex:(NSUInteger)index allowEOL:(BOOL)allowEOL
{
    index = [self startOfLine:index];
    return [self nextNonblankInLineAtIndex:index allowEOL:allowEOL];
}

- (NSUInteger)nextDigitInLine:(NSUInteger)index
{
    xvim_string_buffer_t sb;
    xvim_sb_init(&sb, self.string, index, index, [self endOfLine:index]);

    if (xvim_sb_find_forward(&sb, [NSCharacterSet decimalDigitCharacterSet])) {
        return xvim_sb_index(&sb);
    }

    return NSNotFound;
}

#pragma mark Support for modifications

- (BOOL)isEditing
{
    return _editCount > 0;
}

- (void)undoRedo:(XVimUndoOperation *)op
{
    for (NSLayoutManager *mgr in _textStorage.layoutManagers) {
        NSTextView *view = mgr.firstTextView;

        if (view.textStorage == _textStorage) {
            [op undoRedo:self view:view.xvim_view];
            return;
        }
    }

    [op undoRedo:self view:nil];
}

- (void)beginEditingAtIndex:(NSUInteger)index
{
    NSAssert(!_curOp || _editCount, @"invalid undo state");
    if (_curOp) {
        _editCount++;
        _curOp.startIndex = index;
    } else {
        _curOp = [[XVimUndoOperation alloc] initWithIndex:index];
        _editCount = 1;
    }
}

- (void)endEditingAtIndex:(NSUInteger)index
{
    _curOp.endIndex = index;

    if (--_editCount == 0) {
        [_curOp registerForBuffer:self];
        [_curOp release];
        _curOp = nil;
    }
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    NSAssert(_curOp, @"you must call -beginEditingAtIndex: first");
    [_curOp addUndoRange:range replacementRange:NSMakeRange(range.location, string.length) buffer:self];
    [_textStorage replaceCharactersInRange:range withString:string];
}

- (void)replaceCharactersInRange:(NSRange)range withSpaces:(NSUInteger)count
{
    if (count == 0) {
        [self replaceCharactersInRange:range withString:@""];
    } else if (range.length) {
        [self replaceCharactersInRange:range withString:[NSString stringMadeOfSpaces:count]];
    }
}

NS_INLINE unichar rot13(unichar c)
{
    switch (c) {
    case 'a' ... 'a' + 12:
    case 'A' ... 'A' + 12:
        return c + 13;
    case 'z' - 12 ... 'z':
    case 'Z' - 12 ... 'Z':
        return c - 13;
    }
    return c;
}

- (void)swapCharactersInRange:(NSRange)range mode:(int)mode
{
    NSMutableString *s, *L, *U;
    unichar  buf[XVIM_STRING_BUFFER_SIZE];
    unsigned pos = 0;
    xvim_string_buffer_t sb;

    NSAssert(_curOp, @"you must call -beginEditingAtIndex: first");
    if (!range.length) {
        return;
    }

    CFLocaleRef locale = CFLocaleCopyCurrent();

    if (mode == XVIM_BUFFER_SWAP_UPPER || mode == XVIM_BUFFER_SWAP_LOWER) {
        s = [self.string newMutableSubstringWithRange:range];
        if (mode == XVIM_BUFFER_SWAP_LOWER) {
            CFStringLowercase((CFMutableStringRef)s, locale);
        } else {
            CFStringUppercase((CFMutableStringRef)s, locale);
        }
    } else if (mode == XVIM_BUFFER_SWAP_ROT13) {
        xvim_sb_init_range(&sb, self.string, range);
        s = [[NSMutableString alloc] initWithCapacity:range.length];

        do {
            buf[pos++] = rot13(xvim_sb_peek(&sb));
            if (pos >= XVIM_STRING_BUFFER_SIZE) {
                [s appendCharacters:buf length:pos];
                pos = 0;
            }
        } while (xvim_sb_next(&sb));
        if (pos) {
            [s appendCharacters:buf length:pos];
        }
    } else {
        xvim_sb_init_range(&sb, self.string, range);
        s = [[NSMutableString alloc] initWithCapacity:range.length];
        L = [[NSMutableString alloc] initWithCapacity:1];
        U = [[NSMutableString alloc] initWithCapacity:1];

        do {
            unichar ch = xvim_sb_peek(&sb);

            [L replaceCharactersInRange:NSMakeRange(0, L.length) withString:@""];
            [L appendCharacters:&ch length:1];
            [U replaceCharactersInRange:NSMakeRange(0, U.length) withString:@""];
            [U appendCharacters:&ch length:1];

            CFStringUppercase((CFMutableStringRef)U, locale);
            if ([L isEqualToString:U]) {
                CFStringLowercase((CFMutableStringRef)L, locale);
                [s appendString:L];
            } else {
                [s appendString:U];
            }
        } while (xvim_sb_next(&sb));

        [L release];
        [U release];
    }

    [self replaceCharactersInRange:range withString:s];
    [s release];
    CFRelease(locale);
}

- (void)_removeSpacesAtLine:(NSUInteger)line column:(NSUInteger)column count:(NSUInteger)count
{
    NSUInteger  tabWidth = self.tabWidth;
    NSUInteger  spaces = 0, width = 0, start;
    xvim_string_buffer_t sb;

    start = [self indexOfLineNumber:line column:column];

    xvim_sb_init(&sb, self.string, start, start, self.length);
    if (xvim_sb_peek(&sb) == '\t') {
        spaces = column - [self columnOfIndex:start];
    } else if (xvim_sb_peek(&sb) != ' ') {
        return;
    }

    while (width < count) {
        unichar c = xvim_sb_peek(&sb);

        if (c != ' ' && c != '\t') {
            break;
        }
        if (c == '\t') {
            width += tabWidth - ((column + width) % tabWidth);
        } else {
            width++;
        }

        if (!xvim_sb_next(&sb)) {
            break;
        }
    }

    if (width > count) {
        spaces += width - count;
    }

    NSRange range = xvim_sb_range_to_start(&sb);
    [self replaceCharactersInRange:range withString:[NSString stringMadeOfSpaces:spaces]];
}

- (NSUInteger)shiftLines:(XVimRange)lines column:(NSUInteger)column
                   count:(NSUInteger)count right:(BOOL)right block:(BOOL)blockMode
{
    NSString *string = self.string;

    if (right) {
        NSString  *s = [NSString stringMadeOfSpaces:count];
        NSUInteger tabWidth = self.tabWidth;

        for (NSUInteger line = lines.begin; line <= lines.end; line++) {
            NSUInteger index, spaces = 0;

            index = [self indexOfLineNumber:line column:column];
            if (index >= self.length || isNewline([string characterAtIndex:index])) {
                if (column == 0 || [self columnOfIndex:column] < column) {
                    continue;
                }
            }

            if (tabWidth && [string characterAtIndex:index] == '\t') {
                NSUInteger col = [self columnOfIndex:index];

                spaces = tabWidth - (col % tabWidth);
            }

            if (spaces) {
                NSString *s2 = [NSString stringMadeOfSpaces:count + spaces];
                [self replaceCharactersInRange:NSMakeRange(index, 1) withString:s2];
            } else {
                [self replaceCharactersInRange:NSMakeRange(index, 0) withString:s];
            }
        }
    } else {
        for (NSUInteger line = lines.begin; line <= lines.end; line++) {
            [self _removeSpacesAtLine:line column:column count:count];
        }
    }

    NSUInteger pos;
    if (blockMode) {
        pos = [self indexOfLineNumber:lines.begin column:column];
    } else {
        pos = [self indexOfLineNumber:lines.begin];
        pos = [self firstNonblankInLineAtIndex:pos allowEOL:YES];
    }
    return pos;
}

- (NSRange)_numberAtIndex:(NSUInteger)index
{
    NSUInteger o_start, n_start, x_start;
    NSUInteger o_end, n_end, x_end;
    NSString *s = self.string;
    unichar c;
    BOOL isOctal = YES;
    xvim_string_buffer_t sb;

    xvim_sb_init(&sb, s, index, 0, s.length);
    xvim_sb_skip_forward(&sb, [NSCharacterSet xvim_octDigitsCharacterSet]);
    o_end = xvim_sb_index(&sb);
    xvim_sb_skip_forward(&sb, [NSCharacterSet decimalDigitCharacterSet]);
    n_end = xvim_sb_index(&sb);
    if (o_end != n_end) isOctal = NO;
    xvim_sb_skip_forward(&sb, [NSCharacterSet xvim_hexDigitsCharacterSet]);
    x_end = xvim_sb_index(&sb);

    xvim_sb_init(&sb, s, index, 0, s.length);
    if (isOctal) {
        xvim_sb_skip_backward(&sb, [NSCharacterSet xvim_octDigitsCharacterSet]);
        o_start = xvim_sb_index(&sb);
        c = xvim_sb_peek_prev(&sb);
        if (c == '8' || c == '9' || xvim_sb_peek(&sb) != '0') {
            isOctal = NO;
        }
    }
    xvim_sb_skip_backward(&sb, [NSCharacterSet decimalDigitCharacterSet]);
    n_start = xvim_sb_index(&sb);
    xvim_sb_skip_backward(&sb, [NSCharacterSet xvim_hexDigitsCharacterSet]);
    x_start = xvim_sb_index(&sb);

    // first deal with Hex: 0xNNNNN
    // case 1: check for insertion point on the '0' or 'x'
    if (x_end - x_start == 1) {
        NSUInteger end = x_end;
        if (end < s.length && [s characterAtIndex:end] == 'x') {
            xvim_sb_init(&sb, s, end + 1, 0, s.length);
            xvim_sb_skip_forward(&sb, [NSCharacterSet xvim_hexDigitsCharacterSet]);
            end = xvim_sb_index(&sb);

            if (index < end && end - x_start > 2) {
                // YAY it's hex for real!!!
                return NSMakeRange(x_start, end - x_start);
            }
        }
    }

    // case 2: check whether we're after 0x
    if (index < x_end && x_end - x_start >= 1) {
        if (x_start >= 2 && [s characterAtIndex:x_start - 1] == 'x' && [s characterAtIndex:x_start - 2] == '0') {
            return NSMakeRange(x_start - 2, x_end - x_start + 2);
        }
    }

    if (index == n_end || n_start - n_end == 0) {
        return NSMakeRange(NSNotFound, 0);
    }

    // okay it's not hex, if it's not octal, check for leading +/-
    if (n_start > 0 && !isOctal) {
        c = [s characterAtIndex:n_start - 1];
        if (c == '+' || c == '-') {
            n_start--;
        }
    }
    return NSMakeRange(n_start, n_end - n_start);
}

- (NSUInteger)incrementNumberAtIndex:(NSUInteger)index by:(int64_t)offset
{
    NSRange range;

    range = [self _numberAtIndex:index];
    if (range.location == NSNotFound) {
        NSUInteger pos = [self nextDigitInLine:index];
        if (pos == NSNotFound) {
            return NSNotFound;
        }
        range = [self _numberAtIndex:pos];
        if (range.location == NSNotFound) {
            // should not happen
            return NSNotFound;
        }
    }

    const char *s = [[self.string substringWithRange:range] UTF8String];
    NSString *repl;
    uint64_t u = strtoull(s, NULL, 0);
    int64_t i = strtoll(s, NULL, 0);

    if (strncmp(s, "0x", 2) == 0) {
        repl = [NSString stringWithFormat:@"0x%0*llx", (int)strlen(s) - 2, u + (uint64_t)offset];
    } else if (u && *s == '0' && s[1] && !strchr(s, '9') && !strchr(s, '8')) {
        repl = [NSString stringWithFormat:@"0%0*llo", (int)strlen(s) - 1, u + (uint64_t)offset];
    } else if (u && *s == '+') {
        repl = [NSString stringWithFormat:@"%+lld", i + offset];
    } else {
        repl = [NSString stringWithFormat:@"%lld", i + offset];
    }

    [self beginEditingAtIndex:index];
    [self replaceCharactersInRange:range withString:repl];
    index = range.location + repl.length - 1;
    [self endEditingAtIndex:index];
    return index;
}

- (void)indentCharacterRange:(NSRange)range
{
    if ([_textStorage respondsToSelector:@selector(xvim_indentCharacterRange:buffer:)]) {
        [(id)_textStorage xvim_indentCharacterRange:range buffer:self];
    }
}

@end
