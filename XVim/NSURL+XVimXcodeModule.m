//
//  NSURL+XVimXcodeModule.m
//
//  Created by pebble8888 on 2015/06/25.
//
//

#import "NSURL+XVimXcodeModule.h"
#import "Logger.h"

@implementation NSURL (XVimXcodeModule)
- (BOOL)isXcodeModuleSchemeURL;
{
    return [self.scheme isEqualToString:@"x-xcode-module"];
}

#pragma mark - Xcode6
- (NSString*)xcode_language      { return self.queryString[@"language"]; }
- (NSString*)xcode_source_header { return self.queryString[@"source-header"]; }
- (NSString*)xcode_swift_sdk     { return self.queryString[@"swift-sdk"]; }
- (NSString*)xcode_swift_target  { return self.queryString[@"swift-target"]; }

#pragma mark - add at Xcode7
- (NSString*)xcode_clang_defines            { return self.queryString[@"clang-defines"]; }
- (NSString*)xcode_clang_header_paths       { return self.queryString[@"clang-header-paths" ]; }
- (NSString*)xcode_clang_user_header_paths  { return self.queryString[@"clang-user-header-paths" ]; }
- (NSString*)xcode_source_file              { return self.queryString[@"source-file" ]; }
- (NSString*)xcode_swift_framework_paths    { return self.queryString[@"swift-framework-paths" ]; }
- (NSString*)xcode_swift_header_paths       { return self.queryString[@"swift-header-paths" ]; }
- (NSString*)xcode_swift_module_name        { return self.queryString[@"swift-module-name" ]; }

#pragma mark -
- (NSDictionary*)queryString
{
    NSMutableDictionary *queryStringDictionary = [NSMutableDictionary dictionary];
    NSArray *urlComponents = [self.absoluteString componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in urlComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        [queryStringDictionary setObject:value forKey:key];
    }
    return queryStringDictionary;
}

- (NSString*)xvim_header_file
{
    // Xcode7
    NSString* str = self.xcode_source_file;
    if (str == nil) {
        // Xcode6
        str = self.xcode_source_header;
    }
    return str;
}

- (NSString*)xvim_swiftCacheFilePath
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* xvim_folder = [NSHomeDirectory() stringByAppendingPathComponent:@".xvim"];
    NSString* xvim_caches_folder = [xvim_folder stringByAppendingPathComponent:@"caches"];
    if (![fm fileExistsAtPath:xvim_caches_folder]){
        [fm createDirectoryAtPath:xvim_caches_folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString* header_path = [self xvim_header_file];
    if (header_path == nil) {
        return nil;
    }
    NSString* name = header_path.lastPathComponent.stringByDeletingPathExtension;
    NSString* swiftpath = [xvim_caches_folder stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"swift"]];
    return swiftpath; 
}

@end
