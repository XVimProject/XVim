//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVim.h"
#import "XVimOperatorEvaluator.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimKeymapProvider.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimView.h"
#import "XVimYankEvaluator.h"
#import "XVimShiftEvaluator.h"
#import "XVimJoinEvaluator.h"

@interface XVimOperatorEvaluator() {
}
@end

// TODO: Maybe need to override b,B,w,W operation (See older implementation)

@implementation XVimOperatorEvaluator

+ (XVimEvaluator*)doOperationWithMotion:(XVimMotion*)motion onView:(NSTextView*)view{
    return nil;
}

- (void)dealloc {
    [super dealloc];
}

- (CGFloat)insertionPointHeightRatio{
    return 0.5;
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other{
	return [super isRelatedTo:other] || other == self.parent;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
	return [keymapProvider keymapForMode:XVIM_MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)a{
    [self.argumentString appendString:@"a"];
	return [[[XVimTextObjectEvaluator alloc] initWithWindow:self.window inner:NO] autorelease];
}

// TODO: There used to be "b:" and "B:" methods here. Take a look how they have been.

- (XVimEvaluator*)i{
    [self.argumentString appendString:@"i"];
    return [[[XVimTextObjectEvaluator alloc] initWithWindow:self.window inner:YES] autorelease];
}

- (XVimEvaluator*)_motionFixed:(XVimMotion *)motion{
    // We have to save current selection range before fix the command to pass them to fixOperationCommandInMode...
    XVimEvaluator* evaluator = [super _motionFixed:motion];
    // Fix repeat command for change here (except for Yank)
    // Also need to set "." mark for last change.
    // We do not fix the change here if next evaluator is not nil becaust it waits more input for fix the command.
    // This happens for a command like "cw..."
    if( nil == evaluator ){
        XVimBuffer *buffer = self.window.currentBuffer;
        XVimView   *xview  = self.currentView;
        Class aClass = self.class;

        if (aClass != [XVimYankEvaluator class]) {
            [[XVim instance] fixOperationCommands];
            XVimMark *mark = nil;

            if (aClass == [XVimJoinEvaluator class]) {
                // This is specical case for join operation.
                // The mark is set at the head of next line of the insertion point after the operation
                mark = XVimMakeMark(xview.insertionLine + 1, 0, buffer.document);
            } else if (aClass == [XVimShiftEvaluator class]) {
                mark = XVimMakeMark(xview.insertionLine, 0, buffer.document);
            } else {
                XVimPosition pos = xview.insertionPosition;
                mark = XVimMakeMark(pos.line, pos.column, buffer.document);
            }
            
            if (nil != mark.document) {
                [[XVim instance].marks setMark:mark forName:@"."];
            }
        }
    }
    return evaluator;
}

- (XVimEvaluator*)executeOperationWithMotion:(XVimMotion*)motion{
    return [self _motionFixed:motion];
}

- (XVimEvaluator*)onChildComplete:(XVimEvaluator *)childEvaluator{
    if ([childEvaluator isKindOfClass:[XVimTextObjectEvaluator class]]) {
        return [self _motionFixed:[(XVimTextObjectEvaluator *)childEvaluator motion]];
    }
    return nil;
}
@end
