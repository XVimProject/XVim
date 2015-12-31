//
//  XVimVisualMode.m
//  XVim
//
//  Created by pebble8888 on 2015/08/22.
//
//

#import <Foundation/Foundation.h>
#import "XVimDefs.h"

static const char* s_xvim_visual_mode_name[] = {
    "XVIM_VISUAL_NONE",
    "XVIM_VISUAL_CHARACTER",
    "XVIM_VISUAL_LINE",
    "XVIM_VISUAL_BLOCK",
};

NSString* XVimVisualModeName(XVIM_VISUAL_MODE visual_mode)
{
    return [NSString stringWithFormat:@"%s", s_xvim_visual_mode_name[visual_mode]];
}
