//
//  NSURL+XVimXcodeModule.m
//
//  Created by pebble8888 on 2015/06/25.
//
//

#import "NSURL+XVimXcodeModule.h"

@implementation NSURL (XVimXcodeModule)
- (BOOL)isXcodeModuleSchemeURL;
{
    return [self.scheme isEqualToString:@"x-xcode-module"];
}

@end
