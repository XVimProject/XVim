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
#import "XVimUndo.h"
#import "XVimTextStoring.h"

static char const * const XVIM_KEY_BUFFER = "xvim_buffer";

NS_INLINE BOOL isNewline(unichar ch)
{
    return [[NSCharacterSet newlineCharacterSet] characterIsMember:ch];
}

@implementation XVimBuffer {
    NSDocument    *__unsafe_unretained _document;
    NSTextStorage *__unsafe_unretained _textStorage;

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

+ (XVimBuffer *)makeBufferForDocument:(NSDocument *)document
                          textStorage:(NSTextStorage *)textStorage
{
    XVimBuffer *buffer = document.xvim_buffer;

    if (buffer) return buffer;

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
    NSUInteger lineNum = 0, end = 0, contentsEnd;

    do {
        [string getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(end, 0)];
        lineNum++;
        if (lineNum == num) {
            if (newLineLength) *newLineLength = end - contentsEnd;
            return NSMakeRange(end, contentsEnd - end);
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
    NSUInteger length = self.length, start;
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
    if (newLineLength) *newLineLength = contentEnd - end;
    return NSMakeRange(index, contentEnd - index);
}

- (NSUInteger)indexOfLineNumber:(NSUInteger)num
{
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

- (NSUInteger)numberOfColumnsInLineAtIndex:(NSUInteger)index
{
    NSRange range = [self indexRangeForLineAtIndex:index newLineLength:NULL];
    xvim_string_buffer_t sb;

    xvim_sb_init_range(&sb, self.string, range);
    return xvim_sb_count_columns(&sb, self.tabWidth);
}

- (NSUInteger)indexOfLineNumber:(NSUInteger)num column:(NSUInteger)column
{
	NSUInteger index = [self indexOfLineNumber:num];

    if (column == 0 || index == NSNotFound) {
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

    if (c == XVimInvalidChar || isNewline(c)) {
        return allowEOL ? xvim_sb_index(&sb) : NSNotFound;
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

- (void)undoRedo:(XVimUndoOperation *)op
{
    for (NSLayoutManager *mgr in _textStorage.layoutManagers) {
        NSTextView *view = mgr.firstTextView;

        if (view.textStorage == _textStorage) {
            [op undoRedo:self view:view];
            return;
        }
    }

    [op undoRedo:self view:nil];
}

- (void)replaceCharactersInRange:(NSRange)range
                      withString:(NSString *)string
                      undoObject:(XVimUndoOperation *)op
{
    [op addUndoRange:range replacementRange:NSMakeRange(range.location, string.length) buffer:self];
    [_textStorage replaceCharactersInRange:range withString:string];
}

@end

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
