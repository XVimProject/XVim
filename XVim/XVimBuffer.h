//
//  XVimBuffer.h
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import "XVimTextStoring.h"

@protocol XVimUndoing;

/** @brief class to represent an XVim Buffer
 *
 * If we were writing a vi clone, this would be the object owning the document
 * and the text storage. But since XVim is meant to be a plugin to add vim
 * bindings to existing apps like XCode, this is done in the reverse way.
 *
 * The XVimBuffer is an associated object of the NSDocument and NSTextStorage
 * that the App we're hooking into is supposed to use.
 *
 * XVimBuffer supposes that there's a 1:1 mapping between the document
 * and the storage and owns no reference to either of those.
 *
 * This means that when the document and textstorage get deallocated,
 * either one may be stale, and make the app crash if we try to use them.
 *
 * FIXME: hook into NSDocument/NSTextStorage to invalidate
 *        the XVimBuffer in the rigth places.
 *        This isn't urgent though because IDE uses an NSDocument subclass
 *        that owns its textStorage, hence their lifetime is tied.
 */

@interface XVimBuffer : NSObject

@property (nonatomic, readonly) NSDocument    *document;
@property (nonatomic, readonly) NSTextStorage *textStorage;
@property (nonatomic, readonly) NSUndoManager *undoManager;

+ (XVimBuffer *)makeBufferForDocument:(NSDocument *)document
                          textStorage:(NSTextStorage *)textStorage;

#pragma mark Support for modifications

- (void)undoRedo:(id<XVimUndoing>)op;

@end

@interface NSTextStorage (XVimBuffer)
@property (nonatomic, readonly) XVimBuffer *xvim_buffer;
@end

@interface NSDocument (XVimBuffer)
@property (nonatomic, readonly) XVimBuffer *xvim_buffer;
@end
