//
//  DVTTextSidebarViewHook.h
//  XVim
//
//  Created by Weijing Liu on 2/15/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DVTKit.h"

@interface DVTTextSidebarView (XVim)
+ (void)xvim_initialize;

- (void)xvim__drawLineNumbersInSidebarRect:(struct CGRect)arg1 // doulbe under score (__) is intentional.
                         foldedIndexes:(unsigned long long *)arg2
                                 count:(unsigned long long)arg3
                         linesToInvert:(id)arg4
                        linesToReplace:(id)arg5
                      getParaRectBlock:(id)arg6;


@end
