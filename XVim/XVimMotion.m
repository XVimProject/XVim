//
//  XVimMotion.m
//  XVim
//
//  Created by Suzuki Shuichiro on 9/25/12.
//
//

#import "XVimMotion.h"

static const char* s_motion_name[] = {
    "MOTION_NONE",
    "MOTION_FORWARD",
    "MOTION_BACKWARD",
    "MOTION_WORD_FORWARD",
    "MOTION_WORD_BACKWARD",
    "MOTION_END_OF_WORD_FORWARD",
    "MOTION_END_OF_WORD_BACKWARD",
    "MOTION_LINE_FORWARD",
    "MOTION_LINE_BACKWARD",
    "MOTION_END_OF_LINE",
    "MOTION_BEGINNING_OF_LINE",
    "MOTION_SENTENCE_FORWARD",
    "MOTION_SENTENCE_BACKWARD",
    "MOTION_PARAGRAPH_FORWARD",
    "MOTION_PARAGRAPH_BACKWARD",
    "MOTION_NEXT_FIRST_NONBLANK",
    "MOTION_PREV_FIRST_NONBLANK",
    "MOTION_FIRST_NONBLANK",
    "MOTION_NEXT_CHARACTER",
    "MOTION_PREV_CHARACTER",
    "MOTION_TILL_NEXT_CHARACTER",
    "MOTION_TILL_PREV_CHARACTER",
    "MOTION_LINENUMBER",
    "MOTION_PERCENT",
    "MOTION_NEXT_MATCHED_ITEM",
    "MOTION_LASTLINE",
    "MOTION_HOME",
    "MOTION_MIDDLE",
    "MOTION_BOTTOM",
    "MOTION_SEARCH_FORWARD",
    "MOTION_SEARCH_BACKWARD",
    "TEXTOBJECT_WORD",
    "TEXTOBJECT_SENTENCE",
    "TEXTOBJECT_PARAGRAPH",
    "TEXTOBJECT_SQUAREBRACKETS",
    "TEXTOBJECT_PARENTHESES",
    "TEXTOBJECT_ANGLEBRACKETS",
    "TEXTOBJECT_TAG",
    "TEXTOBJECT_BRACES",
    "TEXTOBJECT_SQUOTE",
    "TEXTOBJECT_DQUOTE",
    "TEXTOBJECT_BACKQUOTE",
    "MOTION_LINE_COLUMN",
    "MOTION_POSITION",
    "MOTION_POSITION_JUMP",
};

@implementation XVimMotionInfo
- (id)init
{
    self = [super init];
    if( self ){
        _reachedEndOfLine = NO;
        _isFirstWordInLine = NO;
        _deleteLastLine = NO;
        _lastEndOfLine = NSNotFound;
        _lastEndOfWord = NSNotFound;
    }
    return self;
}
- (NSString*)description
{
    return [NSString stringWithFormat:
            @"reachedEndOfLine[%d] "
            @"isFirstWordInLine[%d] "
            @"deleteLastLine[%d] "
            @"lastEndOfLine[%@] "
            @"lastEndOfWord[%@] ",
            _reachedEndOfLine,
            _isFirstWordInLine,
            _deleteLastLine,
            _lastEndOfLine==NSNotFound?@"NSNotFound":@(_lastEndOfLine),
            _lastEndOfWord==NSNotFound?@"NSNotfound":@(_lastEndOfWord)];
            
}
@end

@implementation XVimMotion

- (BOOL)isJumpMotion
{
    switch( _motion ){
        case MOTION_SENTENCE_FORWARD:   // )
        case MOTION_SENTENCE_BACKWARD:  // (
        case MOTION_PARAGRAPH_FORWARD:  // }
        case MOTION_PARAGRAPH_BACKWARD: // {
        case MOTION_NEXT_MATCHED_ITEM:  // %
        case MOTION_LINENUMBER:         // [num]G
        case MOTION_PERCENT:            // [num]%
        case MOTION_LASTLINE:           // G
        case MOTION_HOME:               // H
        case MOTION_MIDDLE:             // M
        case MOTION_BOTTOM:             // L
        case MOTION_SEARCH_FORWARD:     // /
        case MOTION_SEARCH_BACKWARD:    // ?
        case MOTION_POSITION_JUMP:      // Custom position change for jump
            return YES;
        default:
            break;
    }
    return NO;
}

- (id) initWithMotion:(MOTION)motion type:(MOTION_TYPE)type option:(MOTION_OPTION)option count:(NSUInteger)count{
    if( self = [super init]){
        _motion = motion;
        _type = type;
        _option = option;
        _count = count;
        _regex = nil;
        
        _info = [[XVimMotionInfo alloc] init];

		_jumpToAnotherFile = NO;
        _markBeforeJumpToAnotherFile = nil;
        _keepJumpMarkIndex = NO;
    }
    return self;
}

- (void)dealloc{
}

- (BOOL)isTextObject{
    return TEXTOBJECT_WORD <= self.motion && self.motion <= TEXTOBJECT_UNDERSCORE;
}

- (NSString*)description{
    return [NSString stringWithFormat:@"motion[%s]\n"
            @"type[%@] "
            @"option[%@] "
            @"%@",
            s_motion_name[_motion], 
            XVimMotionTypeName(_type),
            XVimMotionOptionDescription(_option),
            _info.description];
}

@end
