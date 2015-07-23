//
//  NSURL+XVimXcodeModule.h
//  XVim
//
//  Created by pebble8888 on 2015/06/25.
//
//

#import <Foundation/Foundation.h>

@interface NSURL (XVimXcodeModule)
- (BOOL)isXcodeModuleSchemeURL;
- (NSString*)xcode_language;
- (NSString*)xcode_source_header;
- (NSString*)xcode_swift_sdk;
- (NSString*)xcode_swift_target;
@end
