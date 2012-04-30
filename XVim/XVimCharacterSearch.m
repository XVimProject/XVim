//
//  XVimCharacterSearch.m
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimCharacterSearch.h"
#import "XVimWindow.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"

@interface XVimCharacterSearch()
@property (strong) NSString *searchCharacter;
@end

@implementation XVimCharacterSearch
@synthesize searchCharacter = _searchCharacter;
@synthesize shouldSearchCharacterBackward = _shouldSearchCharacterBackward;
@synthesize shouldSearchPreviousCharacter = _shouldSearchPreviousCharacter;

- (id)init
{
	if (self = [super init])
	{
		_searchCharacter = @"";
		_shouldSearchCharacterBackward = NO;
		_shouldSearchPreviousCharacter = NO;
	}
	return self;
}

- (void)setSearchCharacter:(NSString*)searchChar backward:(BOOL)backward previous:(BOOL)previous{
	self.searchCharacter = searchChar;
	_shouldSearchCharacterBackward = backward;
	_shouldSearchPreviousCharacter = previous;
}

- (NSUInteger)searchCharacterForwardFrom:(NSUInteger)start inWindow:(XVimWindow*)window
{
	XVimSourceView *view = [window sourceView];
	NSString* s = [view string];
	NSRange at = NSMakeRange(start, 0); 
	if (at.location >= s.length-1) {
		return NSNotFound;
	}
	
	NSUInteger eol = [view endOfLine:at.location];
	if (eol == NSNotFound){
		return NSNotFound;
	}
	
	at.length = eol - at.location;
	if (at.location != eol) at.location += 1;
	
	NSString* search_string = [s substringWithRange:at];
	NSRange found = [search_string rangeOfString:self.searchCharacter];
	if (found.location == NSNotFound){
		return NSNotFound;
	}
	
	NSUInteger location = at.location + found.location;
	if (self.shouldSearchPreviousCharacter){
		location -= 1;
	}
	
	return location;
}

- (NSUInteger)searchCharacterBackwardFrom:(NSUInteger)start inWindow:(XVimWindow*)window
{
	XVimSourceView *view = [window sourceView];
	NSString* s = [view string];
	NSRange at = NSMakeRange(start, 0); 
	if (at.location >= s.length-1) {
		return NSNotFound;
	}
	
	NSUInteger hol = [view headOfLine:at.location];
	if (hol == NSNotFound){
		return NSNotFound;
	}
	
	at.length = at.location - hol;
	at.location = hol;
	
	NSString* search_string = [s substringWithRange:at];
	NSRange found = [search_string rangeOfString:self.searchCharacter options:NSBackwardsSearch];
	if (found.location == NSNotFound){
		return NSNotFound;
	}
	
	NSUInteger location = at.location + found.location;
	if (self.shouldSearchPreviousCharacter){
		location += 1;
	}
	
	return location;
}

- (NSUInteger)searchNextCharacterFrom:(NSUInteger)start inWindow:(XVimWindow*)window
{
	if(self.shouldSearchCharacterBackward){
		return [self searchCharacterBackwardFrom:start inWindow:window];
	}else{
		return [self searchCharacterForwardFrom:start inWindow:window];
	}
}

- (NSUInteger)searchPrevCharacterFrom:(NSUInteger)start inWindow:(XVimWindow*)window
{
	if(self.shouldSearchCharacterBackward){
		return [self searchCharacterForwardFrom:start inWindow:window];
	}else{
		return [self searchCharacterBackwardFrom:start inWindow:window];
	}
}

@end

