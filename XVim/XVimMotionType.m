//
//  XVimMotionType.m
//  XVim
//
//  Created by pebble8888 on 2015/08/22.
//
//

#import <Foundation/Foundation.h>
#import "XVimMotionType.h"

static const char* s_motion_type_name[] = {
    "DEFAULT_MOTION_TYPE",
    "CHARACTERWISE_INCLUSIVE",
    "CHARACTERWISE_EXCLUSIVE",
    "LINEWISE",
    "BLOCKWISE",
};

NSString* XVimMotionTypeName(MOTION_TYPE motion_type)
{
    return [NSString stringWithFormat:@"%s", s_motion_type_name[motion_type]];
}
