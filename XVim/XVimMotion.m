//
//  XVimMotion.m
//  XVim
//
//  Created by Suzuki Shuichiro on 9/25/12.
//
//

#import "XVimMotion.h"

@implementation XVimMotion

- (BOOL)isJumpMotion
{
    switch( _motion ){
        case MOTION_SENTENCE_FORWARD:   // )
        case MOTION_SENTENCE_BACKWARD:  // (
        case MOTION_PARAGRAPH_FORWARD:  // }
        case MOTION_PARAGRAPH_BACKWARD: // {
        case MOTION_NEXT_MATCHED_ITEM:  // %
        case MOTION_LINENUMBER:         // [num]G
        case MOTION_PERCENT:            // [num]%
        case MOTION_LASTLINE:           // G
        case MOTION_HOME:               // H
        case MOTION_MIDDLE:             // M
        case MOTION_BOTTOM:             // L
        case MOTION_SEARCH_FORWARD:     // /
        case MOTION_SEARCH_BACKWARD:    // ?
        case MOTION_POSITION_JUMP:      // Custom position change for jump
            return YES;
        default:
            break;
    }
    return NO;
}

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count{
    if( self = [super init]){
        _motion = motion;
        _type = type;
        _option = option;
        _count = count;
        _regex = nil;
        
        _info = malloc(sizeof(XVimMotionInfo));
        _info->reachedEndOfLine = NO;
        _info->isFirstWordInLine = NO;
        _info->lastEndOfLine = NSNotFound;
        _info->lastEndOfWord = NSNotFound;

		_jumpToAnotherFile = NO;
        _keepJumpMarkIndex = NO;
    }
    return self;
}

- (void)dealloc{
    free(_info);
}

- (BOOL)isTextObject{
    return TEXTOBJECT_WORD <= self.motion && self.motion <= TEXTOBJECT_UNDERSCORE;
}
@end
