//
//  DVTTextStorage+XVimTextStoring.h
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import "DVTKit.h"
#import "XVimTextStoring.h"
#import "NSTextStorage+VimOperation.h"

/*
 * This file reimplements some of our default XVimTextStoring implementations
 * on NSTextStorage, with more efficient alternatives.
 */

#if XVIM_XCODE_VERSION == 5

@interface DVTTextStorage (XVimTextStoring) <XVimTextStoring>

@end

#else

@interface DVTSourceTextStorage (XVimTextStoring) <XVimTextStoring>

@end

@interface DVTFoldingTextStorage (XVimTextStoring) <XVimTextStoring>

@end

#endif