//
//  XVimMarkSetEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMarkSetEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVim.h"
#import "XVimView.h"

@implementation XVimMarkSetEvaluator

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    XVimView   *xview  = self.currentView;
    XVimBuffer *buffer = self.window.currentBuffer;

    NSString  *keyStr = [keyStroke toSelectorString];
	if ([keyStr length] != 1) {
        return [XVimEvaluator invalidEvaluator];
    }
    
    XVimMark *mark = [[[XVimMark alloc] init] autorelease];
    XVimPosition pos = xview.insertionPosition;

    mark.line = pos.line;
    mark.column = pos.column;
    mark.document = buffer.document.fileURL.path;
    if (nil != mark.document) {
        [[XVim instance].marks setMark:mark forName:keyStr];
    }
    return nil;
}

@end
