//
//  XVimInfo.m
//  XVim
//
//  Created by Suzuki Shuichiro on 10/17/13.
//
//

#import "XVimInfo.h"


@interface XVimInfo()
@property (strong) NSMutableDictionary* info;
@end

@implementation XVimInfo 

- (id)init{
    if( self = [super init]){
        self.info = [[[NSMutableDictionary alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc{
    self.info = nil;
    [super dealloc];
}

- (void)save{
    NSString *homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString *path = [homeDir stringByAppendingString: @"/.xviminfo"]; 
    NSOutputStream* stream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    NSError* err = [[[NSError alloc] init] autorelease];
    [NSPropertyListSerialization writePropertyList:self.info toStream:stream format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    NSString* selector = NSStringFromSelector(anInvocation.selector);
    if( [selector hasPrefix:@"set"] && selector.length > 3){
        // setter
        NSString* propName = [selector substringFromIndex:3];
        id obj;
        [anInvocation getArgument:&obj atIndex:0];
        [self.info setObject:obj forKey:propName];
    }else{
        // getter
        NSString* propName = selector;
        id obj = [self.info objectForKey:propName];
        [anInvocation setReturnValue:&obj];
    }
}

- (NSDictionary*)testCategories{
    return @{ @"ab":@1 };
}

- (BOOL)respondsToSelector:(SEL)aSelector{
    return YES;
}


@end
