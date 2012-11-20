//
//  XVimYunkedText.m
//  XVim
//
//  Created by Suzuki Shuichiro on 11/10/12.
//
//

#import "XVimText.h"

@implementation XVimText
@synthesize string = _string;

- (id)init{
    if(self = [super init]){
        _string = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
    [_string release];
}

- (NSString *)description{
    return [self string];
}

- (void)appendString:(NSString *)string{
    NSAssert( string != nil, @"string must be not nil");
    [(NSMutableString*)_string appendString:string];
}

- (void)clear{
    [((NSMutableString*)_string) setString:@""];
}

- (id)copyWithZone:(NSZone *)zone{
    XVimText* copiedObject = [[XVimText allocWithZone:zone] init];
    copiedObject->_string = [_string copyWithZone:zone];
    return copiedObject;
}

@end
