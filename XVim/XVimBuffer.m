//
//  XVimBuffer.m
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import <objc/runtime.h>
#import "XVimBuffer.h"
#import "XVimUndo.h"

static char const * const XVIM_KEY_BUFFER = "xvim_buffer";

@implementation XVimBuffer {
    NSDocument    *__unsafe_unretained _document;
    NSTextStorage *__unsafe_unretained _textStorage;
}
@synthesize document = _document;
@synthesize textStorage = _textStorage;

- (NSUndoManager *)undoManager
{
    return _document.undoManager;
}

- (instancetype)initWithDocument:(NSDocument *)document
                     textStorage:(NSTextStorage *)textStorage
{
    if ((self = [super init])) {
        _document    = document;
        _textStorage = textStorage;
        objc_setAssociatedObject(document, XVIM_KEY_BUFFER, self, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(textStorage, XVIM_KEY_BUFFER, self, OBJC_ASSOCIATION_RETAIN);
    }
    return self;
}

+ (XVimBuffer *)makeBufferForDocument:(NSDocument *)document
                          textStorage:(NSTextStorage *)textStorage
{
    XVimBuffer *buffer = document.xvim_buffer;

    if (buffer) return buffer;

    return [[[[self class] alloc] initWithDocument:document textStorage:textStorage] autorelease];
}

#pragma mark Support for modifications

- (void)undoRedo:(id<XVimUndoing>)op
{
    [op undoRedo:self];
}

@end

@implementation NSTextStorage (XVimBuffer)

- (XVimBuffer *)xvim_buffer
{
    return objc_getAssociatedObject(self, XVIM_KEY_BUFFER);
}

@end

@implementation NSDocument (XVimBuffer)

- (XVimBuffer *)xvim_buffer
{
    return objc_getAssociatedObject(self, XVIM_KEY_BUFFER);
}

@end
