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
- (NSString*)xcode_clang_defines;
- (NSString*)xcode_clang_header_paths;
- (NSString*)xcode_clang_user_header_paths;
- (NSString*)xcode_source_file;
- (NSString*)xcode_swift_framework_paths;
- (NSString*)xcode_swift_header_paths;
- (NSString*)xcode_swift_module_name;
- (NSString*)xvim_header_file;
- (NSString*)xvim_swiftCacheFilePath;
@end
