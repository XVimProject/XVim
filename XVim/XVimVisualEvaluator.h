//
//  XVimVisualEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"

typedef enum{
    MODE_CHARACTER, // for 'v'
    MODE_LINE, // for 'V'
    MODE_BLOCK // for 'CTRL-V'. may be implemented later...
}VISUAL_MODE;

@interface XVimVisualEvaluator : XVimTextObjectEvaluator{
    // _begin may be greater than _end ( in case of backward selection )
    NSUInteger _begin;
    NSUInteger _insertion;
    VISUAL_MODE _mode;
}
- (id)initWithMode:(VISUAL_MODE)mode initialSelection:(NSUInteger)begin :(NSUInteger)end;
@end
