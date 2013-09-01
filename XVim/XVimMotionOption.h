//
//  XVimMotionOption.h
//  XVim
//
//  Created by Tomas Lundell on 10/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

typedef enum{
    MOTION_OPTION_NONE = 0x00,
    LEFT_RIGHT_WRAP = 0x01,
    LEFT_RIGHT_NOWRAP = 0x02,
    BIGWORD = 0x04, // for 'WORD' motion
    INCLUSIVE = 0x08,
    MOPT_PARA_BOUND_BLANKLINE = 0x10,
    TEXTOBJECT_INNER = 0x20,
    SEARCH_WRAP= 0x40,
    SEARCH_CASEINSENSITIVE = 0x80,
} MOTION_OPTION;
