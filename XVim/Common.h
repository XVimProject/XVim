//
//  Header.h
//  XVim
//
//  Created by Morris on 12-2-26.
//  Copyright (c) 2012年 http://warwithinme.com . All rights reserved.
//

#import <Foundation/Foundation.h>

// =======================
// Use xv_set_string() and xv_set_index() to set the information,
// before calling other xv_xxxxx() functions !!!!!
// Usage example:
// xv_set_string([textview textStorage] string]);
// xv_set_index([textview selectedRange].location);
// NSInteger newIdx = xv_dollar();
void xv_set_string(NSString*);
void xv_set_index(NSInteger);

// =======================
// Return the location of the start of indentation on current line. '^'
NSInteger xv_caret(NSString *string, NSInteger index);
// Return the beginning of line location. '0'
NSInteger xv_0(NSString *string, NSInteger index);
// Return the end of the line. '$'
NSInteger xv_dollar(NSString *string, NSInteger index);
// This one returns index of the CR
NSInteger xv_dollar_inc(NSString *string, NSInteger index);
// Return the last non-blank of the line. 'g_'
NSInteger xv_g_(NSString *string, NSInteger index);
// Return the index after procesing %
NSInteger xv_percent(NSString *string, NSInteger index);
// Return the index of the character in the column of current line.
NSInteger xv_columnToIndex(NSString *string, NSInteger index, NSUInteger column);
// Return the new location of the caret, after handler h,j,w,W,e,E,b,B
NSInteger xv_h(NSString *string, NSInteger index, int repeatCount);
NSInteger xv_l(NSString *string, NSInteger index, int repeatCount, BOOL stepForward);
NSInteger xv_b(NSString *string, NSInteger index, int repeatCount, BOOL bigWord);
NSInteger xv_e(NSString *string, NSInteger index, int repeatCount, BOOL bigWord);
NSInteger xv_w(NSString *string, NSInteger index, int repeatCount, BOOL bigWord);
// xv_w_motion slightly differs from xv_w.
NSInteger xv_w_motion(NSString *string, NSInteger index, int repeatCount, BOOL bigWord);
// There's no function by now for 'j' and 'k', 
// since NSTextView has a moveUp: and moveDown: method

// Unlike vim, this function won't ignore indent before the current character
// even if what is '{'
NSRange xv_current_block(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what, char other);
NSRange xv_current_word(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, BOOL fuzzy);
NSRange xv_current_quote(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what);
NSRange xv_current_tagblock(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive);

// Find char in current line.
// Return the current index if nothing found.
// If inclusive is YES :
//   'fx' returns the index after 'x'
//   'Fx' returns the index before 'x'
NSInteger xv_findChar(NSString *string, NSInteger index, int repeatCount, char command, unichar what, BOOL inclusive);

// ==========
// Instead of using NSCharacterSet, these functions make it simple and fast.
// Even fast-typing.
BOOL testDigit(unichar ch);
BOOL testAlpha(unichar ch);
BOOL testDelimeter(unichar ch);
BOOL testWhiteSpace(unichar ch);
BOOL testNonAscii(unichar ch);
BOOL testNewLine(unichar ch);
BOOL testFuzzyWord(unichar ch);


/*
 * NSStringHelper is used to provide fast character iteration.
 */
#define ITERATE_STRING_BUFFER_SIZE 64
typedef struct s_NSStringHelper
{
    unichar    buffer[ITERATE_STRING_BUFFER_SIZE];
    NSString*  string;
    NSUInteger strLen;
    NSInteger  index;
    
} NSStringHelper;

void initNSStringHelper(NSStringHelper*, NSString* string, NSUInteger strLen);
void initNSStringHelperBackward(NSStringHelper*, NSString* string, NSUInteger strLen);
unichar characterAtIndex(NSStringHelper*, NSInteger index);
