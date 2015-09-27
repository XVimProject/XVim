//
//  DVTTextCompletionController+XVim.m
//  XVim
//
//  Created by Muronaka Hiroaki on 2015/09/27.
//
//

#import "DVTTextCompletionController+XVim.h"
#import "DVTTextCompletionListWindowController+XVim.h"
#import "NSObject+XVimAdditions.h"

@implementation DVTTextCompletionController (XVim)

+ (void)xvim_initialize {
    [self xvim_swizzleInstanceMethod:@selector(acceptCurrentCompletion) with:@selector(xvim_acceptCurrentCompletion)];
}

+ (void)xvim_finalize {
    [self xvim_swizzleInstanceMethod:@selector(acceptCurrentCompletion) with:@selector(xvim_acceptCurrentCompletion)];
}

- (BOOL)xvim_acceptCurrentCompletion {
    
    if([self.currentSession.listWindowController tryExpandingCompletion]) {
        return YES;
    }
    
    return [self xvim_acceptCurrentCompletion];
}

@end
