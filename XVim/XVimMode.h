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
	MODE_GLOBAL_MAP,
	MODE_COUNT,
} XVIM_MODE;

static NSString* MODE_STRINGS[] = {@"NORMAL", @"CMDLINE", @"INSERT", 
    @"VISUAL", @"OPERATOR"};
