//
//  XVimTest.h
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import <Foundation/Foundation.h>
#import "XVimWindow.h"
#import "Test/XVimTestCase.h"

@interface XVimTester : NSObject<NSTableViewDataSource, NSTableViewDelegate>

// Get all the caregory of tests
- (NSArray*)categories;

// Select test categories to run
- (void)selectCategories:(NSArray*)categories;

// Run tests
- (void)runTest;
@end
