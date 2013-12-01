//
//  XVimChildEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimArgumentEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVimKeymapProvider.h"

@implementation XVimArgumentEvaluator
@synthesize keyStroke = _keyStroke;

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    self.keyStroke = keyStroke;
    return [self onArgumentProvided:keyStroke];
}

- (XVimEvaluator*)onArgumentProvided:(XVimKeyStroke*)key{
    return nil;
}

- (void)dealloc{
    self.keyStroke = nil;
    [super dealloc];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
    return [keymapProvider keymapForMode:XVIM_MODE_NONE];
}
@end
