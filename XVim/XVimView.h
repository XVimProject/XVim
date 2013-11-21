//
//  XVimView.h
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <Cocoa/Cocoa.h>

@class XVimView, XVimBuffer, XVimWindow;

@interface NSTextView (XVimView)
@property (readonly, nonatomic) XVimView *xvim_view;

- (XVimView *)xvim_makeXVimViewInWindow:(XVimWindow *)window;
@end

@interface XVimView : NSObject
@property (readonly, nonatomic) XVimWindow *window;
@property (readonly, nonatomic) NSTextView *textView;

- (instancetype)initWithView:(NSTextView *)view window:(XVimWindow *)window;

@end
