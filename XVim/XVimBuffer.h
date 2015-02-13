//
//  XVimBuffer.h
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import "XVimTextStoring.h"

@interface XVimBuffer : NSObject

@property (weak, nonatomic, readonly) XVimTextStorage *textStorage;

@end
