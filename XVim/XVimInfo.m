//
//  XVimInfo.m
//  XVim
//
//  Created by Suzuki Shuichiro on 10/17/13.
//
//

#import "XVimInfo.h"

@implementation XVimInfo 

- (void)save{
    NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString *path = [homeDir stringByAppendingString: @"/.xviminfo"]; 
    NSOutputStream* stream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    NSError* err = [[[NSError alloc] init] autorelease];
    [NSPropertyListSerialization writePropertyList:self toStream:stream format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
}

- (NSMutableDictionary*)testCategories{
    return [self objectForKey:@"TestCategories"];
}

@end
