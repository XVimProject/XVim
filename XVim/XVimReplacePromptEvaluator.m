//
//  XVimReplacePromptEvaluator.h
//  XVim
//
//  Created by Jeff Pearce on 2/19/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "XVimReplacePromptEvaluator.h"
#import "XVimSearch.h"
#import "XVimWindow.h"

@implementation XVimReplacePromptEvaluator

- (instancetype)initWithWindow:(XVimWindow *)window replacementString:(NSString*)replacementString
{
    if (self = [super initWithWindow:window]) {
        self.replaceModeString = [NSString stringWithFormat:@"replace with %@ (y/n/a/q/l/^E/^Y)?", replacementString];
    }
    return self;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke {

    XVimSearch *searcher = [[XVim instance] searcher];

    if (keyStroke.modifier == 0) {
        switch (keyStroke.character) {
            case 'y':
                [searcher replaceCurrentInWindow:self.window findNext:YES];

                if (searcher.lastFoundRange.location == NSNotFound) {
                    return nil;
                }
                break;
            case 'n':
                [searcher skipCurrentInWindow:self.window];
                if (searcher.lastFoundRange.location == NSNotFound) {
                    return nil;
                }
                break;
            case 'a':
                [searcher replaceCurrentToEndInWindow:self.window];
                break;
            case 'l':
                [searcher replaceCurrentInWindow:self.window findNext:NO];
                return nil;
                break;

            case 'q':
                return nil;
                break;
            default:
                break;
        }
    }
    else if (keyStroke.modifier & 4) {
        switch (keyStroke.character) {
            case 'e':
                if (self.window.sourceView.currentLineNumber > (long long)[self.window.sourceView xvim_lineNumberFromTop:1]) {
                    [self.window.sourceView xvim_scrollLineForward:1];
                }
                break;
            case 'y':
                if (self.window.sourceView.currentLineNumber < (long long)[self.window.sourceView xvim_lineNumberFromBottom:1]) {
                    [self.window.sourceView xvim_scrollLineBackward:1];
                }
                break;
            default:
                break;
        }
    }
    return self;
}

- (NSString*)modeString{
    return self.replaceModeString;
}

- (XVIM_MODE)mode{
    return XVIM_MODE_NORMAL;
}

@end
