//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVim.h"
#import "XVimOperatorEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimKeymapProvider.h"
#import "XVimMark.h"
#import "XVimMarks.h"

@interface XVimOperatorEvaluator() {
}
@end

// TODO: Maybe need to override b,B,w,W operation (See older implementation)

@implementation XVimOperatorEvaluator

- (id)initWithWindow:window{
	if (self = [super initWithWindow:window]){
	}
	return self;
}

- (void)drawRect:(NSRect)rect{
	return [self.parent drawRect:rect];
}

- (void)dealloc {
    [super dealloc];
}

- (float)insertionPointHeightRatio{
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
        XVimSourceView* view = self.window.sourceView;
        if( ![NSStringFromClass([self class]) isEqualToString:@"XVimYankEvaluator"]){
            [[XVim instance] fixOperationCommands];
            XVimMark* mark = XVimMakeMark([self.sourceView insertionLine], [self.sourceView insertionColumn], view.documentURL.path);
            [[XVim instance].marks setMark:mark forName:@"."];
        }
    }
    return evaluator;
}
@end
