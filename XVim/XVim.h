//
//  XVim.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimCommandLine.h"
#import "XVimRegister.h"
#import "XVimMode.h"
#import "XVimSearch.h"
#import "XVimExCommand.h"
#import "XVimOptions.h"
#import "XVimPlaybackHandler.h"

@class XVimEvaluator;
@class DVTSourceTextView;
@class XVimKeymap;
@class XVimSourceCodeEditor;


#define XVIM_TAG 1209 // This is my birthday!

@interface XVim : NSTextView <NSTextFieldDelegate,XVimCommandFieldDelegate,XVimPlaybackHandler>
 {
@private
     //NSMutableString* _lastSearchString;
     //NSUInteger _nextSearchBaseLocation;
     // BOOL _searchBackword;
     NSMutableString* _lastReplacedString;
     NSMutableString* _lastReplacementString;
     NSUInteger _nextReplaceBaseLocation;
     NSUInteger _numericArgument;
     XVimEvaluator* _currentEvaluator;
     NSMutableDictionary* _localMarks; // key = single letter mark name. value = NSRange (wrapped in a NSValue) for mark location
	 XVimKeymap* _keymaps[MODE_COUNT];
}

@property NSInteger tag;
@property (readonly) NSInteger mode;
@property BOOL handlingMouseClick;
@property(retain) XVimCommandLine* cmdLine;
@property(retain) DVTSourceTextView* sourceView;
@property(strong, readonly) NSSet* registers;
@property(weak, readonly) XVimRegister *recordingRegister;
@property(readonly) XVimEvaluator *currentEvaluator;
@property(readonly) BOOL shouldSearchCharacterBackward;
@property(readonly) BOOL shouldSearchPreviousCharacter;

@property (strong) XVimSearch* searcher;
@property (strong) XVimExCommand* excmd;
@property (strong) XVimOptions* options;
@property (weak) XVimSourceCodeEditor* editor;

// In normal mode, if when moving the caret to somewhere, and it might be at the newline character.
// Mark this property to YES before moving. And mark it to NO after moving.
@property(assign) BOOL dontCheckNewline;

- (NSString*)string;
- (NSRange)selectedRange;
- (void)commandModeWithFirstLetter:(NSString*)first;
- (void)searchNext;
- (void)searchPrevious;
- (NSUInteger)searchCharacterNext:(NSUInteger)start;
- (NSUInteger)searchCharacterPrevious:(NSUInteger)start;
- (void)setSearchCharacter:(NSString*)searchChar backward:(BOOL)backward previous:(BOOL)previous;
- (NSString*)modeName;
- (BOOL)handleKeyEvent:(NSEvent*)event;
- (NSMutableDictionary *)getLocalMarks;
- (void)statusMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)ringBell;
- (void)setNextSearchBaseLocation:(NSUInteger)location;
- (XVimRegister*)findRegister:(NSString*)name;
- (void)recordIntoRegister:(XVimRegister*)xregister;
- (void)stopRecordingRegister:(XVimRegister*)xregister;
- (void)playbackRegister:(XVimRegister*)xregister withRepeatCount:(NSUInteger)count;
- (XVimKeymap*)keymapForMode:(int)mode;

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke;
- (void)handleTextInsertion:(NSString*)text;

// Message from XVimCommandField 
- (BOOL)commandCanceled;
- (BOOL)commandFixed:(NSString*)command;

@end