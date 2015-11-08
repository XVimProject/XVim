//
//  DVTSourceTextScrollViewHook.h
//  XVim
//
//  Created by Suzuki Shuichiro on 11/8/13.
//
//

#import <Foundation/Foundation.h>
#import "DVTKit.h"

@interface DVTSourceTextScrollView(XVim)
+ (void)xvim_initialize;
- (void)xvim_viewWillMoveToWindow:(NSWindow*)window;
- (void)xvim_observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context;
@end