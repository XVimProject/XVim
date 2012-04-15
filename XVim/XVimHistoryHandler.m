//
//  XVimHistoryHandler.m
//  XVim
//
//  Created by Tomas Lundell on 15/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHistoryHandler.h"

@interface XVimHistoryHandler() {
	NSMutableArray *_history;
}
@end

@implementation XVimHistoryHandler

- (id)init
{
	if (self = [super init])
	{
		_history = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)addEntry:(NSString*)entry
{
	[_history insertObject:entry atIndex:0];
}

- (NSString*) entry:(NSUInteger)no withPrefix:(NSString*)str
{
    NSAssert( no != 0, @"no starts from 1" );
    NSUInteger count = 0;
    for( NSString* s in _history ){
        if( [s hasPrefix:str] ){
            count++;
            if( no == count){
                return s;
            }
        }
    }
	return nil;
}

@end
