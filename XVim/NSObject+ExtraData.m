//
//  NSObject+ExtraData.m
//  XVim
//
//  Created by Suzuki Shuichiro on 3/24/13.
//
//

#import "NSObject+ExtraData.h"
#import <objc/runtime.h>
#import "Logger.h"

static const NSString* EXTRA_DATA_KEY = @"EXTRADATAKEY";
@implementation NSObject (ExtraData)

- (id)dataForName:(NSString*)name{
    NSMutableDictionary* dic = objc_getAssociatedObject(self , EXTRA_DATA_KEY);
    if( nil == dic ){
        return nil;
    }
    
    id ret = [dic objectForKey:name];
    if( [NSNull null] == ret ){
        return nil;
    }else{
        return ret;
    }
}

- (void)setData:(id)data forName:(NSString*)name{
    NSMutableDictionary* dic = objc_getAssociatedObject(self , EXTRA_DATA_KEY);
    if( nil == dic ){
        dic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, EXTRA_DATA_KEY, dic, OBJC_ASSOCIATION_RETAIN);
    }
    
    if( nil == data){
        data = [NSNull null];
    }
    [dic setObject:data forKey:name];
}

- (void)setBool:(BOOL)b forName:(NSString *)name{
    NSNumber* n = [NSNumber numberWithBool:b];
    [self setData:n forName:name];
}

- (void)setUnsignedInteger:(NSUInteger)b forName:(NSString *)name{
    NSNumber* n = [NSNumber numberWithUnsignedInteger:b];
    [self setData:n forName:name];
}

- (void)setInteger:(NSInteger)b forName:(NSString *)name{
    NSNumber* n = [NSNumber numberWithInteger:b];
    [self setData:n forName:name];
}
@end
