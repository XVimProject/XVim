//
//  DVTSourceTextScrollViewHook.h
//  XVim
//
//  Created by Suzuki Shuichiro on 11/8/13.
//
//

#import <Foundation/Foundation.h>
#import "DVTKit.h"

@interface DVTSourceTextScrollViewHook : NSObject
+ (void)hook;
+ (void)unhook;
@end

@interface DVTSourceTextScrollView(Hook)
- (id)initWithFrame_:(NSRect)rect;
- (void)dealloc_;
- (BOOL)hasHorizontalScroller_;
- (BOOL)hasVerticalScroller_;
@end