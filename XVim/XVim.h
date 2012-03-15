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
@class XVimEvaluator;

enum{
    MODE_NORMAL,
    MODE_CMDLINE,
    MODE_INSERT,
    MODE_VISUAL
};


static NSString* MODE_STRINGS[] = {@"NORMAL", @"CMDLINE", @"INSERT", 
    @"VISUAL"};

#define XVIM_TAG 1209 // This is my birthday!

@interface XVim : NSTextView <NSTextFieldDelegate>
 {
@private
     NSMutableString* _lastSearchString;
     NSUInteger _nextSearchBaseLocation;
     BOOL _searchBackword;
     BOOL _ignoreCase;
     BOOL _wrapScan;
     BOOL _errorBells;
     NSMutableString* _lastReplacedString;
     NSMutableString* _lastReplacementString;
     NSUInteger _nextReplaceBaseLocation;
     NSUInteger _numericArgument;
     XVimEvaluator* _currentEvaluator;
     NSMutableDictionary* _localMarks; // key = single letter mark name. value = NSRange (wrapped in a NSValue) for mark location
}

@property NSInteger tag;
@property NSInteger mode;
@property(retain) XVimCommandLine* cmdLine;
@property(retain) NSTextView* sourceView;
@property(strong, readonly) NSSet* registers;
@property(readonly) BOOL isPlayingRegisterBack;
@property(weak, readonly) XVimRegister *recordingRegister;

// In normal mode, if when moving the caret to somewhere, and it might be at the newline character.
// Mark this property to YES before moving. And mark it to NO after moving.
@property(assign) BOOL dontCheckNewline;

- (void)commandModeWithFirstLetter:(NSString*)first;
- (void)commandDetermined:(NSString*)command;
- (void)commandCanceled;
- (void)searchNext;
- (void)searchPrevious;
- (void)searchForward;
- (void)searchBackward;
- (NSString*)modeName;
- (BOOL)handleKeyEvent:(NSEvent*)event;
- (NSMutableDictionary *)getLocalMarks;
- (NSInteger)wordCharSetIdForChar:(unichar)c;
- (NSRange)wordForward:(NSTextView *)view begin:(NSRange)at;
- (NSRange)wordBackward:(NSTextView *)view begin:(NSRange)at;
- (void)statusMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)ringBell;
- (void)setNextSearchBaseLocation:(NSUInteger)location;
- (NSUInteger)getNextSearchBaseLocation;
- (XVimRegister*)findRegister:(NSString*)name;
- (void)recordIntoRegister:(XVimRegister*)xregister;
- (void)stopRecordingRegister:(XVimRegister*)xregister;
- (void)playbackRegister:(XVimRegister*)xregister withRepeatCount:(NSUInteger)count;
@end
