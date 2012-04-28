//
//  DVTFondAndColorTheme.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVTFontAndColorTheme : NSObject
{
    NSString *_name;
    NSImage *_image;
    NSURL *_dataURL;
    //DVTCustomDataSpecifier *_customDataSpecifier;
    NSColor *_sourceTextBackgroundColor;
    NSColor *_sourceTextSidebarBackgroundColor;
    NSColor *_sourceTextSidebarNumbersColor;
    NSColor *_sourceTextFoldbarBackgroundColor;
    NSColor *_sourceTextSelectionColor;
    NSColor *_sourceTextInsertionPointColor;
    NSColor *_sourceTextInvisiblesColor;
    NSColor *_sourceTextBlockDimBackgroundColor;
    NSColor *_sourceTextTokenizedBorderColor;
    NSColor *_sourceTextTokenizedBackgroundColor;
    NSColor *_sourceTextTokenizedBorderSelectedColor;
    NSColor *_sourceTextTokenizedBackgroundSelectedColor;
    NSColor *_consoleTextBackgroundColor;
    NSColor *_consoleTextSelectionColor;
    NSColor *_consoleTextInsertionPointColor;
    NSColor *_consoleDebuggerPromptTextColor;
    NSColor *_consoleDebuggerInputTextColor;
    NSColor *_consoleDebuggerOutputTextColor;
    NSColor *_consoleExecutableInputTextColor;
    NSColor *_consoleExecutableOutputTextColor;
    NSFont *_consoleDebuggerPromptTextFont;
    NSFont *_consoleDebuggerInputTextFont;
    NSFont *_consoleDebuggerOutputTextFont;
    NSFont *_consoleExecutableInputTextFont;
    NSFont *_consoleExecutableOutputTextFont;
    NSColor *_debuggerInstructionPointerColor;
    NSColor *_sourcePlainTextColor;
    NSFont *_sourcePlainTextFont;
    NSPointerArray *_syntaxColorsByNodeType;
    NSPointerArray *_syntaxFontsByNodeType;
    NSColor *_sourceTextCompletionPreviewColor;
    BOOL _builtIn;
    BOOL _loadedData;
    BOOL _contentNeedsSaving;
    BOOL _hasMultipleSourceTextFonts;
}

+ (id)_defaultSourceCodeFont;
+ (id)titleForNewPreferenceSetFromTemplate;
+ (id)preferenceSetsListHeader;
+ (id)preferenceSetsFileExtension;
+ (id)defaultKeyForExcludedBuiltInPreferenceSets;
+ (id)defaultKeyForCurrentPreferenceSet;
+ (id)builtInPreferenceSetsDirectoryURL;
+ (id)systemPreferenceSet;
+ (id)preferenceSetGroupingName;
+ (id)_nodeTypesIncludedInPreferences;
+ (id)_stringRepresentationOfFont:(id)arg1;
+ (id)_fontWithName:(id)arg1 size:(double)arg2;
+ (id)currentTheme;
+ (id)preferenceSetsManager;
+ (void)initialize;
@property(readonly) BOOL loadedData; // @synthesize loadedData=_loadedData;
@property(readonly) NSPointerArray *syntaxFontsByNodeType; // @synthesize syntaxFontsByNodeType=_syntaxFontsByNodeType;
@property(readonly) NSPointerArray *syntaxColorsByNodeType; // @synthesize syntaxColorsByNodeType=_syntaxColorsByNodeType;
@property BOOL hasMultipleSourceTextFonts; // @synthesize hasMultipleSourceTextFonts=_hasMultipleSourceTextFonts;
@property BOOL contentNeedsSaving; // @synthesize contentNeedsSaving=_contentNeedsSaving;
//@property DVTCustomDataSpecifier *customDataSpecifier; // @synthesize customDataSpecifier=_customDataSpecifier;
@property(readonly, getter=isBuiltIn) BOOL builtIn; // @synthesize builtIn=_builtIn;
//@property NSImage *image; // @synthesize image=_image;
@property(copy) NSString *name; // @synthesize name=_name;
- (void)setFont:(id)arg1 forNodeTypes:(id)arg2;
- (void)setColor:(id)arg1 forNodeTypes:(id)arg2;
- (void)_setColorOrFont:(id)arg1 forNodeTypes:(id)arg2;
- (id)fontForNodeType:(short)arg1;
- (id)colorForNodeType:(short)arg1;
@property(readonly) NSFont *sourcePlainTextFont;
@property(readonly) NSColor *sourcePlainTextColor;
- (void)setDebuggerInstructionPointerColor:(NSColor*)arg1;
- (void)setConsoleExecutableOutputTextFont:(NSFont*)arg1;
- (void)setConsoleExecutableInputTextFont:(NSFont*)arg1;
- (void)setConsoleDebuggerOutputTextFont:(NSFont*)arg1;
- (void)setConsoleDebuggerInputTextFont:(NSFont*)arg1;
- (void)setConsoleDebuggerPromptTextFont:(NSFont*)arg1;
- (void)setConsoleExecutableOutputTextColor:(NSColor*)arg1;
- (void)setConsoleExecutableInputTextColor:(NSColor*)arg1;
- (void)setConsoleDebuggerOutputTextColor:(NSColor*)arg1;
- (void)setConsoleDebuggerInputTextColor:(NSColor*)arg1;
- (void)setConsoleDebuggerPromptTextColor:(NSColor*)arg1;
- (void)primitiveSetConsoleDebuggerPromptTextColor:(NSColor*)arg1;
- (void)setConsoleTextInsertionPointColor:(NSColor*)arg1;
- (void)setConsoleTextSelectionColor:(NSColor*)arg1;
- (void)setConsoleTextBackgroundColor:(NSColor*)arg1;
- (void)setSourceTextInvisiblesColor:(NSColor*)arg1;
- (void)setSourceTextInsertionPointColor:(NSColor*)arg1;
- (void)setSourceTextSelectionColor:(NSColor*)arg1;
- (void)setSourceTextBackgroundColor:(NSColor*)arg1;
- (void)_setColorOrFont:(id)arg1 forKey:(id)arg2 colorOrFontivar:(id *)arg3;
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
- (id)description;
@property(readonly) NSString *localizedName;
- (void)_updateHasMultipleSourceTextFonts;
- (void)_updateDerivedColors;
- (BOOL)_loadFontsAndColors;
- (id)dataRepresentationWithError:(id *)arg1;
- (id)initWithCustomDataSpecifier:(id)arg1 basePreferenceSet:(id)arg2;
- (id)initWithName:(id)arg1 dataURL:(id)arg2;
- (id)_initWithName:(id)arg1 syntaxColorsByNodeType:(id)arg2 syntaxFontsByNodeType:(id)arg3;
- (void)_themeCommonInit;
- (id)init;

@end
