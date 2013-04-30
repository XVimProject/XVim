//
//  XVimTest.h
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import <Foundation/Foundation.h>
#import "XVimWindow.h"
#import "XVimTestCase.h"

@interface XVimTester : NSObject<NSTableViewDataSource, NSTableViewDelegate>
@property (strong) NSMutableArray* testCases;
- (void)runTest;
@end
