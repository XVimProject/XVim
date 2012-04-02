//
//  XVimVisualEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"

typedef enum{
    MODE_CHARACTER, // for 'v'
    MODE_LINE, // for 'V'
    MODE_BLOCK // for 'CTRL-V'. may be implemented later...
}VISUAL_MODE;

@interface XVimVisualEvaluator : XVimMotionEvaluator{
    // _begin may be greater than _insertion ( in case of backward selection )
    NSUInteger _begin;  // Position Start of the Visual mode
    NSUInteger _insertion; //  Current cursor position
    NSUInteger _selection_begin; // Begining of selection (This is differ from _begin when its MODE_LINE)
    NSUInteger _selection_end;  // End of selection (This is differ from _insertion when its MODE_LINE)
    VISUAL_MODE _mode;
}
@property (readonly) NSUInteger insertionPoint;
- (id)initWithMode:(VISUAL_MODE)mode;
- (void)updateSelection;
- (XVimEvaluator*)ESC:(id)arg;
@end
