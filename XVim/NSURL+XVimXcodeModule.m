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

- (NSString*)xcode_language
{
    return self.queryString[@"language"];
}

- (NSString*)xcode_source_header
{
    return self.queryString[@"source-header"];
}

- (NSString*)xcode_swift_sdk
{
    return self.queryString[@"swift-sdk"];
}

- (NSString*)xcode_swift_target
{
    return self.queryString[@"swift-target"];
}

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

@end
