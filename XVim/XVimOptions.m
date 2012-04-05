//
//  XVimOptions.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimOptions.h"

@interface XVimOptions() {
@private
    NSDictionary* _option_maps;
}
@end

@implementation XVimOptions
@synthesize ignorecase,wrapscan,errorbells;

- (id)init{
    if( self = [super init] ){
        // Abbreviation mapping
        _option_maps = [[NSDictionary alloc] initWithObjectsAndKeys:
            @"ignorecase",@"ic",
            @"wrapscan",@"ws",
            @"errorbells",@"eb",
        nil];
        
        // Default values
        ignorecase = NO;
        wrapscan = YES;
        errorbells = NO;
    }
    return self;
}

- (void)dealloc{
    [_option_maps release];
    [super dealloc];
}

- (id)getOption:(NSString*)name{
    NSString* propName = name;
    if( [_option_maps objectForKey:name] ){
        // If the name is abbriviation use full name
        propName = [_option_maps objectForKey:name];
    }
    if( [self respondsToSelector:NSSelectorFromString(propName)] ){
        return [self valueForKey:propName];
    }else{
        return nil;
    }
}

- (void)setOption:(NSString*)name value:(id)value{
    NSString* propName = name;
    if( [_option_maps objectForKey:name] ){
        // If the name is abbriviation use full name
        propName = [_option_maps objectForKey:name];
    }
    
    if( [self respondsToSelector:NSSelectorFromString(propName)] ){
        [self setValue:value forKey:propName];
    }
}


@end


