//
//  XVimDefs.h
//  XVim
//
//  Created by Suzuki Shuichiro on 7/27/13.
//
//

#ifndef XVim_XVimDefs_h
#define XVim_XVimDefs_h

typedef enum {
    XVIM_MODE_NONE,
    XVIM_MODE_NORMAL,
    XVIM_MODE_CMDLINE,
    XVIM_MODE_INSERT,
	XVIM_MODE_OPERATOR_PENDING,
    XVIM_MODE_VISUAL,
    XVIM_MODE_SELECT,
	XVIM_MODE_COUNT,        // This is the count of modes
} XVIM_MODE;

typedef enum {
    XVIM_VISUAL_NONE,
    XVIM_VISUAL_CHARACTER, // for 'v'
    XVIM_VISUAL_LINE, // for 'V'
    XVIM_VISUAL_BLOCK, // for 'CTRL-V'
}XVIM_VISUAL_MODE;


typedef struct _XVimRange {
    NSUInteger begin; // begin may be greater than end
    NSUInteger end;
} XVimRange;

typedef struct _XVimPosition{
    NSUInteger line;
    NSUInteger column;
} XVimPosition;

NS_INLINE XVimRange XVimMakeRange(NSUInteger begin, NSUInteger end) {
    XVimRange r;
    r.begin = begin;
    r.end = end;
    return r;
}

NS_INLINE XVimPosition XVimMakePosition(NSUInteger line, NSUInteger column) {
    XVimPosition p;
    p.line = line;
    p.column = column;
    return p;
}

#endif
