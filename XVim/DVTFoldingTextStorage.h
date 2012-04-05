//
//  DVTFoldingTextStorage.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class DVTFontAndColorsTheme;
@class DVTUndoManager;

@interface DVTFoldingTextStorage : NSTextStorage
- (DVTFontAndColorsTheme*)fontAndColorTheme;
- (void)indentCharacterRange:(NSRange)range undoManager:(DVTUndoManager*)undoManager;
- (NSUInteger)numberOfLines;
@end