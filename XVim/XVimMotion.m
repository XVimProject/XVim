//
//  XVimMotion.m
//  XVim
//
//  Created by Suzuki Shuichiro on 9/25/12.
//
//

#import "XVimMotion.h"

@implementation XVimMotion
@synthesize motion = _motion;
@synthesize type = _type;
@synthesize option = _option;
@synthesize count = _count;
@synthesize line = _line;
@synthesize column = _column;
@synthesize position = _position;
@synthesize character = _character;
@synthesize regex = _regex;
@synthesize info = _info;

- (NSInteger)scount
{
    return (NSInteger)_count;
}

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(XVimMotionOptions)option count:(NSUInteger)count{
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
    [_regex release];
    free(_info);
    [super dealloc];
}

- (BOOL)isTextObject{
    return TEXTOBJECT_WORD <= self.motion && self.motion <= TEXTOBJECT_BACKQUOTE;
}
@end
