//
//  XVimMotionOption.m
//  XVim
//
//  Created by pebble8888 on 2015/08/22.
//
//

#import <Foundation/Foundation.h>
#import "XVimMotionOption.h"

NSString* XVimMotionOptionDescription(MOTION_OPTION option)
{
    NSMutableString* str = [NSMutableString string];
    if( option & LEFT_RIGHT_WRAP)                   [str appendString:@"LEFT_RIGHT_WRAP\n"];
    if( option & LEFT_RIGHT_NOWRAP)                 [str appendString:@"LEFT_RIGHT_NOWRAP\n"];
    if( option & BIGWORD )                          [str appendString:@"BIGWORD\n"];
    if( option & DISPLAY_LINE )                     [str appendString:@"DISPLAY_LINE\n"];
    if( option & MOPT_PARA_BOUND_BLANKLINE )        [str appendString:@"MOPT_PARA_BOUND_BLANKLINE"];
    if( option & TEXTOBJECT_INNER )                 [str appendString:@"TEXTOBJECT_INNER"];
    if( option & SEARCH_WRAP )                      [str appendString:@"SEARCH_WRAP"];
    if( option & SEARCH_CASEINSENSITIVE)            [str appendString:@"SEARCH_CASEINSENSITIVE"];
    if( option & MOTION_OPTION_CHANGE_WORD )        [str appendString:@"MOTION_OPTION_CHANGE_WORD"];
    if( option & MOTION_OPTION_SKIP_ADJACENT_CHAR ) [str appendString:@"MOTION_OPTION_SKIP_ADJACENT_CHAR"];
    if( option & MOPT_PLACEHOLDER )                 [str appendString:@"MOPT_PLACEHOLDER"];
    return str;
}
