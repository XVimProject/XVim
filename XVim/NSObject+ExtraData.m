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

@interface XVimPerformOnDealloc : NSObject
+(instancetype)performOnDeallocWithBlock:(void(^)(void))block;
@end

@interface XVimPerformOnDealloc ()
@property (copy) void(^block)(void);
@end

@implementation XVimPerformOnDealloc

// designated block is executed when returned object is deallocated.
+(instancetype)performOnDeallocWithBlock:(void(^)(void))block
{
    XVimPerformOnDealloc* obj = [ self new ];
    obj.block = block;
    return obj;
}
- (void)dealloc
{
    if (self.block) {
        self.block();
    }
}
@end


static const NSString* EXTRA_DATA_KEY = @"EXTRADATAKEY";
@implementation NSObject (ExtraData)

- (id)dataForName:(NSString*)name{
    NSMutableDictionary* dic = objc_getAssociatedObject(self , (__bridge const void *)(EXTRA_DATA_KEY));
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

-(void)xvim_performOnDealloc:(void(^)(void))deallocBlock
{
    [ self setData:[XVimPerformOnDealloc performOnDeallocWithBlock:deallocBlock] forName:@"XVimPerformOnDealloc"];
}

- (void)setData:(id)data forName:(NSString*)name{
    NSMutableDictionary* dic = objc_getAssociatedObject(self , (__bridge const void *)(EXTRA_DATA_KEY));
    if( nil == dic ){
        dic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, (__bridge const void *)(EXTRA_DATA_KEY), dic, OBJC_ASSOCIATION_RETAIN);
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

- (BOOL)boolForName:(NSString*)name
{
    NSNumber* n = [ self dataForName:name ];
    return n ? n.boolValue : NO;
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
