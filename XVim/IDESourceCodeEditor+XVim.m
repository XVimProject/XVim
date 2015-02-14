//
//  XVimSourceCodeEditor.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDESourceCodeEditor+XVim.h"
#import "IDEKit.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimStatusLine.h"
#import "XVim.h"
#import "NSObject+XVimAdditions.h"

@implementation IDESourceCodeEditor(XVim)
+ (void)xvim_initialize{
    [self xvim_swizzleInstanceMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) with:@selector(xvim_textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
}

- (NSArray*) xvim_textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    return newSelectedCharRanges;
}
@end