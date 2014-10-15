//
//  XVimMotion.m
//  XVim
//
//  Created by Suzuki Shuichiro on 9/25/12.
//
//

#import "XVimMotion.h"

@implementation XVimMotion

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
    }
    return self;
}

- (void)dealloc{
    free(_info);
}

- (BOOL)isTextObject{
    return TEXTOBJECT_WORD <= self.motion && self.motion <= TEXTOBJECT_BACKQUOTE;
}
@end
