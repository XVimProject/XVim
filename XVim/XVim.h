//
//  XVim.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimCommandLine.h"
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
     NSUInteger _lastSearchIndex;
     BOOL _searchBackword;
     BOOL _ignoreCase;
     BOOL _wrapScan;
     NSUInteger _numericArgument;
     XVimEvaluator* _currentEvaluator;
     NSMutableDictionary* _localMarks; // key = single letter mark name. value = NSRange (wrapped in a NSValue) for mark location
}

@property NSInteger tag;
@property NSInteger mode;
@property(retain) XVimCommandLine* cmdLine;
@property(retain) NSTextView* sourceView;



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
@end