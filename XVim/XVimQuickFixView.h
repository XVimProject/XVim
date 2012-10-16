//
//  XVimQuickFixView.h
//  XVim
//
//  Created by Ant on 16/10/2012.
//
//

#import <Cocoa/Cocoa.h>

@interface XVimQuickFixView : NSScrollView
@property (nonatomic,assign) NSTextView* textView;

@end
extern NSString* XVimNotificationQuickFixDidComplete ;