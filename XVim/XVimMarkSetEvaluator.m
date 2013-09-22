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
#import "NSTextView+VimOperation.h"

@implementation XVimMarkSetEvaluator

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    NSString* keyStr = [keyStroke toSelectorString];
	if ([keyStr length] != 1) {
        return [XVimEvaluator invalidEvaluator];
    }
    
    XVimMark* mark = [[[XVimMark alloc] init] autorelease];
	NSRange r = [self.sourceView selectedRange];
    mark.line = [self.sourceView.textStorage lineNumber:r.location];
    mark.column = [self.sourceView.textStorage columnNumber:r.location];
    mark.document = [[self.sourceView documentURL] path];
    if( nil != mark.document ){
        [[XVim instance].marks setMark:mark forName:keyStr];
    }
    return nil;
}

@end
