//
//  XVimDefs.h
//  XVim
//
//  Created by Suzuki Shuichiro on 7/27/13.
//
//

#ifndef XVim_XVimDefs_h
#define XVim_XVimDefs_h

#import <Foundation/Foundation.h>

#ifndef NS_REQUIRES_SUPER
#if __has_attribute(objc_requires_super)
#define NS_REQUIRES_SUPER __attribute__((objc_requires_super))
#else
#define NS_REQUIRES_SUPER
#endif
#endif

typedef NS_ENUM(uint8_t, XVimInsertionPoint) {
    XVIM_INSERT_DEFAULT,
    XVIM_INSERT_APPEND,
    XVIM_INSERT_BEFORE_FIRST_NONBLANK,
    XVIM_INSERT_APPEND_EOL,
    XVIM_INSERT_BLOCK_KILL,
};

typedef NS_ENUM(uint8_t, XVimSortOptions) {
    XVimSortOptionReversed              = 1,
    XVimSortOptionRemoveDuplicateLines  = 1 << 1,
    XVimSortOptionNumericSort           = 1 << 2,
    XVimSortOptionIgnoreCase            = 1 << 3
};

typedef NS_OPTIONS(unsigned , XVimMotionOptions) {
    MOPT_NONE                   = 0x00,
    MOPT_NOWRAP                 = 0x01, // whether we stop or wrap at EOL
    MOPT_BIGWORD                = 0x02, // for 'WORD' motion
    MOPT_PARA_BOUND_BLANKLINE   = 0x04,
    MOPT_TEXTOBJECT_INNER       = 0x08,
    MOPT_SEARCH_WRAP            = 0x10,
    MOPT_SEARCH_CASEINSENSITIVE = 0x20,
    MOPT_CHANGE_WORD            = 0x40, // for 'cw','cW'
};

typedef enum{
    TEXT_TYPE_CHARACTERS,
    TEXT_TYPE_BLOCK,
    TEXT_TYPE_LINES
} TEXT_TYPE;

typedef enum {
    CURSOR_MODE_COMMAND, // default must be command
    CURSOR_MODE_INSERT,
} CURSOR_MODE;

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

typedef NS_ENUM(uint8_t, XVimVisualMode) {
    XVIM_VISUAL_NONE,
    XVIM_VISUAL_CHARACTER, // for 'v'
    XVIM_VISUAL_LINE, // for 'V'
    XVIM_VISUAL_BLOCK, // for 'CTRL-V'
};

typedef enum {
    _XVIM_VISUAL_RIGHT  = 1,
    _XVIM_VISUAL_BOTTOM = 2,

    XVIM_VISUAL_TOPLEFT     = 0,
    XVIM_VISUAL_TOPRIGHT    = 1,
    XVIM_VISUAL_BOTTOMLEFT  = 2,
    XVIM_VISUAL_BOTTOMRIGHT = 3,
} XVIM_VISUAL_CORNER;

typedef struct _XVimRange {
    NSUInteger begin; // begin may be greater than end
    NSUInteger end;
} XVimRange;

typedef struct _XVimPosition{
    NSUInteger line;
    NSUInteger column;
} XVimPosition;

typedef struct _XVimSelection {
    XVIM_VISUAL_CORNER corner;
    NSUInteger         top;
    NSUInteger         left;
    NSUInteger         bottom;
    NSUInteger         right;
} XVimSelection;

typedef struct {
    XVimVisualMode mode;
    NSUInteger     colwant;
    XVimPosition   start;
    XVimPosition   end;
} XVimVisualInfo;

#define XVimSelectionEOL  (NSIntegerMax - 1)

NS_INLINE NSUInteger XVimVisualInfoColumns(XVimVisualInfo *vi)
{
    if (vi->end.column == XVimSelectionEOL) {
        return XVimSelectionEOL;
    }
    return MAX(vi->end.column, vi->start.column) - MIN(vi->end.column, vi->start.column) + 1;
}

NS_INLINE NSUInteger XVimVisualInfoLines(XVimVisualInfo *vi)
{
    return MAX(vi->end.line, vi->start.line) - MIN(vi->end.line, vi->start.line) + 1;
}

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

NS_INLINE XVimRange XVimRangeSwap(XVimRange range)
{
    return XVimMakeRange(range.end, range.begin);
}

/** Returns an NSRange from start to end inclusive
 */
NS_INLINE NSRange XVimMakeNSRange(XVimRange range)
{
    return NSMakeRange(range.begin, range.end - range.begin + 1);
}

#endif
