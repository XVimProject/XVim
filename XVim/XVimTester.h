//
//  XVimTest.h
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import <Foundation/Foundation.h>
#import "XVimWindow.h"

@interface XVimTester : NSObject<NSTableViewDataSource, NSTableViewDelegate>
@property (strong) NSArray* testCases;
- (void)runTest;
@end
