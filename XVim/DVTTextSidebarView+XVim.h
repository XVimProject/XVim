//
//  DVTTextSidebarViewHook.h
//  XVim
//
//  Created by Weijing Liu on 2/15/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DVTKit.h"
#import "DVTTextSidebarView.h"

@interface DVTTextSidebarView (XVim)
+ (void)xvim_initialize;

// double under-score (__) is intentional.

// Xcode 8
- (void)xvim__drawLineNumbersInSidebarRect:(CGRect)arg1
                             foldedIndexes:(NSUInteger *)arg2
                                     count:(NSUInteger)arg3
                             linesToInvert:(id)arg4
                          linesToHighlight:(id)arg5
                            linesToReplace:(id)arg6
                                  textView:(id)arg7
                          getParaRectBlock:(GetParaBlock)arg8;

// Pre-Xcode 8
- (void)xvim__drawLineNumbersInSidebarRect:(struct CGRect)arg1
                             foldedIndexes:(unsigned long long *)arg2
                                     count:(unsigned long long)arg3
                             linesToInvert:(id)arg4
                            linesToReplace:(id)arg5
                          getParaRectBlock:(id)arg6;

@end
