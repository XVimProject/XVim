//
//  XVimCharacterSearch.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimWindow;

@interface XVimCharacterSearch : NSObject
@property(readonly) BOOL shouldSearchCharacterBackward;
@property(readonly) BOOL shouldSearchPreviousCharacter;

- (NSUInteger)searchNextCharacterFrom:(NSUInteger)start inWindow:(XVimWindow*)window;
- (NSUInteger)searchPrevCharacterFrom:(NSUInteger)start inWindow:(XVimWindow*)window;
- (void)setSearchCharacter:(NSString*)searchChar backward:(BOOL)backward previous:(BOOL)previous;
@end
