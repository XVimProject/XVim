//
//  DVTTextSidebarViewHook.h
//  XVim
//
//  Created by Weijing Liu on 2/15/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DVTKit.h"

@interface DVTTextSidebarViewHook : NSObject
+ (void)hook;
+ (void)unhook;
@end

@interface DVTTextSidebarView (Hook)
- (void)_drawLineNumbersInSidebarRect_:(struct CGRect)arg1
                         foldedIndexes:(unsigned long long *)arg2
                                 count:(unsigned long long)arg3
                         linesToInvert:(id)arg4
                        linesToReplace:(id)arg5
                      getParaRectBlock:(id)arg6;
@end
