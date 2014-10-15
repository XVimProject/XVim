//
//  XVimMotion.h
//  XVim
//
//  Created by Suzuki Shuichiro on 9/25/12.
//
//

#import <Foundation/Foundation.h>
#import "XVimMotionType.h"
#import "XVimMotionOption.h"

typedef struct {
    BOOL reachedEndOfLine;
    BOOL isFirstWordInLine;
    BOOL deleteLastLine;
    NSUInteger lastEndOfLine;
    NSUInteger lastEndOfWord;
}XVimMotionInfo;

#define XVIM_MAKE_MOTION(MOTION,TYPE,OPTION,COUNT) [[XVimMotion alloc] initWithMotion:MOTION type:TYPE option:OPTION count:COUNT]

typedef enum _MOTION{
    MOTION_NONE,                    
    MOTION_FORWARD,                 // l
    MOTION_BACKWARD,                // h
    MOTION_WORD_FORWARD,            // w,W
    MOTION_WORD_BACKWARD,           // b
    MOTION_END_OF_WORD_FORWARD,     // e,E
    MOTION_END_OF_WORD_BACKWARD,    // ge,gE
    MOTION_LINE_FORWARD,            // k
    MOTION_LINE_BACKWARD,           // j
    MOTION_END_OF_LINE,             // $
    MOTION_BEGINNING_OF_LINE,       // 0
    MOTION_SENTENCE_FORWARD,
    MOTION_SENTENCE_BACKWARD,
    MOTION_PARAGRAPH_FORWARD,
    MOTION_PARAGRAPH_BACKWARD,
    MOTION_NEXT_FIRST_NONBLANK,     // +
    MOTION_PREV_FIRST_NONBLANK,     // -
    MOTION_FIRST_NONBLANK,          // ^
    MOTION_NEXT_CHARACTER,          // f
    MOTION_PREV_CHARACTER,          // F
    MOTION_TILL_NEXT_CHARACTER,     // t
    MOTION_TILL_PREV_CHARACTER,     // T
    MOTION_LINENUMBER,              // [num]G
    MOTION_PERCENT,                 // [num]%
    MOTION_NEXT_MATCHED_ITEM,       // %
    MOTION_LASTLINE,                // G
    MOTION_HOME,                    // H
    MOTION_MIDDLE,                  // M
    MOTION_BOTTOM,                  // L
    MOTION_SEARCH_FORWARD,          // /
    MOTION_SEARCH_BACKWARD,         // ?
    TEXTOBJECT_WORD,
    //TEXTOBJECT_BIGWORD,           // Use motion option
    TEXTOBJECT_SENTENCE,
    TEXTOBJECT_PARAGRAPH,
    TEXTOBJECT_SQUAREBRACKETS,      // [] block
    TEXTOBJECT_PARENTHESES,         // () block
    TEXTOBJECT_ANGLEBRACKETS,       // <> block
    TEXTOBJECT_TAG,                 // <>...</> block
    TEXTOBJECT_BRACES,              // {} block
    TEXTOBJECT_SQUOTE,
    TEXTOBJECT_DQUOTE,
    TEXTOBJECT_BACKQUOTE,
    MOTION_LINE_COLUMN,             // For custom (Line,Column) position
    MOTION_POSITION,                // For custom position
}MOTION;

@interface XVimMotion : NSObject
@property MOTION motion;
@property MOTION_TYPE type;
@property MOTION_OPTION option;
@property NSUInteger count;
@property NSUInteger line;
@property NSUInteger column;
@property NSUInteger position;
@property unichar character;
@property(strong) NSString* regex;
@property XVimMotionInfo* info;

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count;
- (BOOL) isTextObject;
@end 