//
//  XVimYunkedText.m
//  XVim
//
//  Created by Suzuki Shuichiro on 11/10/12.
//
//

#import "XVimText.h"

@implementation XVimText
@synthesize type = _type;
@synthesize strings = _strings;
@synthesize string = _string;

- (id)init{
    if(self = [super init]){
        _type = TEXT_TYPE_CHARACTERS;
        _strings = [[NSMutableArray alloc] init];
        _string = nil;
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
    [_strings release];
}

- (NSString*)string{
    NSAssert( _strings != nil, @"_strings should not be nil");
    if(_strings.count == 0){
        return @"";
    }
    
    return [_strings objectAtIndex:0];
}

- (void)appendString:(NSString *)string{
    NSAssert( string != nil, @"string must be not nil");
    NSAssert( _strings != nil, @"_strings should not be nil");
    if( _strings.count == 0){
        [_strings addObject:@""];
    }

    NSString* firstString = [_strings objectAtIndex:0];
    [_strings replaceObjectAtIndex:0 withObject:[firstString stringByAppendingString:string]];
}

- (void)clear{
    self.type = 0;
    [_strings removeAllObjects];
    [_string release];
    _string = nil;
}
@end
