//
//  XVimMode.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

typedef enum {
    MODE_NORMAL,
    MODE_CMDLINE,
    MODE_INSERT,
    MODE_VISUAL,
	MODE_OPERATOR_PENDING,
	MODE_GLOBAL_MAP, // Used by map
	MODE_NONE, // Use to make sure you get no mapping
	MODE_COUNT,
} XVIM_MODE;
