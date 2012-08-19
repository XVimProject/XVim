//
//  XVimTest.h
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import <Foundation/Foundation.h>
#import "XVimWindow.h"

@interface XVimTester : NSObject
@property (strong)XVimWindow* window;
- (id)initWithWindow:(XVimWindow*)window;
- (void)runTest;
@end
