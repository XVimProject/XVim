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

#define XVIM_MAKE_MOTION(MO,TY,OP,CT) [[[XVimMotion alloc] initWithMotion:MO type:TY option:OP count:CT] autorelease]

typedef enum _MOTION{
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
    MOTION_LINENUMBER,              // [num]G
    MOTION_LASTLINE,                // G
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

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count;
@end 