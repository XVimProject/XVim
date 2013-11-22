//
//  XVimView.h
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <Cocoa/Cocoa.h>
#import "XVimDefs.h"

@class XVimView, XVimBuffer, XVimWindow;

@interface NSTextView (XVimView)
@property (readonly, nonatomic) XVimView *xvim_view;

- (XVimView *)xvim_makeXVimViewInWindow:(XVimWindow *)window;
@end

/**
 * This is the interface to operate on text view used in XVim.
 * Text views want to communicate with XVim handlers(evaluators) must implement this protocol.
 **/

@protocol XVimTextViewDelegateProtocol
- (void)textView:(NSTextView*)view didYank:(NSString*)yankedText withType:(TEXT_TYPE)type;
- (void)textView:(NSTextView*)view didDelete:(NSString*)deletedText withType:(TEXT_TYPE)type;
@end

@interface XVimView : NSObject
@property (readonly, nonatomic) XVimWindow *window;
@property (readonly, nonatomic) NSTextView *textView;

- (instancetype)initWithView:(NSTextView *)view window:(XVimWindow *)window;

#pragma mark *** Drawing ***

- (NSUInteger)lineNumberInScrollView:(CGFloat)ratio offset:(NSInteger)offset;

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color
                     heightRatio:(CGFloat)heightRatio
                      widthRatio:(CGFloat)widthRatio
                           alpha:(CGFloat)alpha;

#pragma mark *** Scrolling ***

- (void)scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollTo:(NSUInteger)location;
- (void)scrollPageForward:(NSUInteger)count;
- (void)scrollPageBackward:(NSUInteger)count;
- (void)scrollHalfPageForward:(NSUInteger)count;
- (void)scrollHalfPageBackward:(NSUInteger)count;
- (void)scrollLineForward:(NSUInteger)count;
- (void)scrollLineBackward:(NSUInteger)count;

@end
