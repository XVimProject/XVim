//
//  DVTFontAndColorsTheme.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface DVTFontAndColorsTheme : NSObject
@property(readonly) NSFont *sourcePlainTextFont;
@property(readonly) NSColor *sourcePlainTextColor;
@property(readonly) NSColor *debuggerInstructionPointerColor;
@property(readonly) NSFont *consoleExecutableOutputTextFont;
@property(readonly) NSFont *consoleExecutableInputTextFont;
@property(readonly) NSFont *consoleDebuggerOutputTextFont;
@property(readonly) NSFont *consoleDebuggerInputTextFont;
@property(readonly) NSFont *consoleDebuggerPromptTextFont;
@property(readonly) NSColor *consoleExecutableOutputTextColor;
@property(readonly) NSColor *consoleExecutableInputTextColor;
@property(readonly) NSColor *consoleDebuggerOutputTextColor;
@property(readonly) NSColor *consoleDebuggerInputTextColor;
@property(readonly) NSColor *consoleDebuggerPromptTextColor;
@property(readonly) NSColor *consoleTextInsertionPointColor;
@property(readonly) NSColor *consoleTextSelectionColor;
@property(readonly) NSColor *consoleTextBackgroundColor;
@property(readonly) NSColor *sourceTextTokenizedBackgroundSelectedColor;
@property(readonly) NSColor *sourceTextTokenizedBorderSelectedColor;
@property(readonly) NSColor *sourceTextTokenizedBackgroundColor;
@property(readonly) NSColor *sourceTextTokenizedBorderColor;
@property(readonly) NSColor *sourceTextLinkColor;
@property(readonly) NSColor *sourceTextCompletionPreviewColor;
@property(readonly) NSColor *sourceTextBlockDimBackgroundColor;
@property(readonly) NSColor *sourceTextInvisiblesColor;
@property(readonly) NSColor *sourceTextInsertionPointColor;
@property(readonly) NSColor *sourceTextSelectionColor;
@property(readonly) NSColor *sourceTextFoldbarBackgroundColor;
@property(readonly) NSColor *sourceTextSidebarNumbersColor;
@property(readonly) NSColor *sourceTextSidebarBackgroundColor;
@property(readonly) NSColor *sourceTextBackgroundColor;
@end