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
@synthesize position = _position;
@synthesize info = _info;

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count{
    if( self = [super init]){
        _motion = motion;
        _type = type;
        _option = option;
        _count = count;
        
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
    [super dealloc];
}
@end
