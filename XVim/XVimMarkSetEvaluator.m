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

    if (keyStroke.modifier) {
        return [XVimEvaluator invalidEvaluator];
    }
    switch (keyStroke.character) {
    case 'a' ... 'z':
    case 'A' ... 'Z':
    case '0' ... '9':
    case '\'': case '"':
    case '[': case ']':
        break;
    default:
        return [XVimEvaluator invalidEvaluator];
    }

    XVimMark *mark = [[[XVimMark alloc] init] autorelease];
    XVimPosition pos = xview.insertionPosition;

    mark.line = pos.line;
    mark.column = pos.column;
    mark.document = buffer.document.fileURL.path;
    if (nil != mark.document) {
        unichar c = keyStroke.character;
        [[XVim instance].marks setMark:mark forName:[NSString stringWithCharacters:&c length:1]];
    }
    return nil;
}

@end
