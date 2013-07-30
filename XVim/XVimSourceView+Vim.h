//
//  XVimSourceView+VimOption.h
//  XVim
//
//  Created by Tomas Lundell on 30/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimSourceView.h"
#import "XVimMotionType.h"
#import "XVimMotionOption.h"

/**
 Vim category on XVimSourceView
 
 Adds Vim-like functionality to XVimSourceView.
 
 Code in here may only use public functionality from XVimSourceView.
 In particular, direct use of "view" is prohibited.

 **/

////////////////////////
// Term Definitions   //
////////////////////////

@class XVimRegister;


typedef enum {
    XVimSortOptionReversed              = 1,
    XVimSortOptionRemoveDuplicateLines  = 1 << 1,
    XVimSortOptionNumericSort           = 1 << 2,
    XVimSortOptionIgnoreCase            = 1 << 3
} XVimSortOptions;

@interface XVimSourceView(Vim)


/**
 * Adjust cursor position if the position is not valid as normal mode cursor position
 * This method may changes selected range of the view.
 **/
- (void)adjustCursorPosition;


/**
 * This does all the work need to do with vim '%' motion.
 * Find match pair character in the line and find the corresponding pair.
 * Returns NSNotFound if not found.
 **/
- (NSUInteger)positionOfMatchedPair:(NSUInteger)pos;

- (NSUInteger)numberOfLinesInView;
- (NSUInteger)lineNumberFromBottom:(NSUInteger)count;
- (NSUInteger)lineNumberAtMiddle;
- (NSUInteger)lineNumberFromTop:(NSUInteger)count;
    
// Clamps range to end of line
- (void)clampRangeToEndOfLine:(NSRange*)range;

// Clamps range to buffer
- (void)clampRangeToBuffer:(NSRange*)range;

// Motions
- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info;
- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info;
- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)endOfWordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt; //e,E
- (NSUInteger)endOfWordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt; //ge,gE
- (NSUInteger)sentencesForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)sentencesBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)paragraphsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)paragraphsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)nextCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(MOTION_OPTION)opt;
- (NSUInteger)prevCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(MOTION_OPTION)opt;


// Scrolls
- (void)pageForward:(NSUInteger)index count:(NSUInteger)count;
- (void)pageBackward:(NSUInteger)index count:(NSUInteger)count;
- (void)halfPageForward:(NSUInteger)index count:(NSUInteger)count;
- (void)halfPageBackward:(NSUInteger)index count:(NSUInteger)count;

// Text Object
- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;

// The following code is from xVim by WarWithinMe.
// These will be integreted into NSTextView category.

// =======================
// Return the location of the start of indentation on current line. '^'
NSInteger xv_caret(NSString *string, NSInteger index);
// Return the beginning of line location. '0'
NSInteger xv_0(NSString *string, NSInteger index);

// Unlike vim, this function won't ignore indent before the current character
// even if what is '{'
NSRange xv_current_block(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what, char other);
NSRange xv_current_quote(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what);

// Find char in current line.
// Return the current index if nothing found.
// If inclusive is YES :
//   'fx' returns the index after 'x'
//   'Fx' returns the index before 'x'
NSInteger xv_findChar(NSString *string, NSInteger index, int repeatCount, char command, unichar what, BOOL inclusive);


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

//- (void)deleteTextIntoYankRegister:(XVimRegister*)xregister; // Deletes the selected range and adjusts cursor position

// Selection
- (void)moveCursorWithBoundsCheck:(NSUInteger)to;
- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to;
- (NSRange)getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)selectOperationTargetFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;


// Sorting
- (void)sortLinesInRange:(NSRange)range withOptions:(XVimSortOptions)options;

@end
