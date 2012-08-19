//
//  XVimTest.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import "XVimTester.h"
#import <objc/runtime.h>
#import "Logger.h"

@implementation XVimTester
@synthesize window = _window;

- (id)initWithWindow:(XVimWindow*)window{
    if (self = [super init]) {
        self.window = window;
	}
	return self;
}

- (void)runTest{
    unsigned int count;
    Method* m = class_copyMethodList([self class], &count);
    for( unsigned int i = 0 ; i < count; i++ ){
        if( [NSStringFromSelector(method_getName(m[i])) hasPrefix:@"test_"] ){
            [self performSelector:method_getName(m[i])];
        }
    }
}

- (void)test_search{
    // Initaila State
    // Execute commands
    // Check text
    // Check selection state ( including cursor position )
}
@end
