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
    MOTION_FORWARD,
    MOTION_BACKWARD,
    MOTION_WORD_FORWARD,
    MOTION_WORD_BACKWARD,
    MOTION_LINE_FORWARD,
    MOTION_LINE_BACKWARD,
    MOTION_END_OF_LINE,
    MOTION_BEGINNING_OF_LINE,
    MOTION_SENTENCE_FORWARD,
    MOTION_SENTENCE_BACKWARD,
    MOTION_PARAGRAPH_FORWARD,
    MOTION_PARAGRAPH_BACKWARD,
    MOTION_NEXT_CHARACTER,
    MOTION_PREV_CHARACTER,
    MOTION_POSITION,
}MOTION;

@interface XVimMotion : NSObject
@property MOTION motion;
@property MOTION_TYPE type;
@property MOTION_OPTION option;
@property NSUInteger count; // I do not know if the count should be here or not
@property NSUInteger position;
@property unichar character;

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count;
@end 