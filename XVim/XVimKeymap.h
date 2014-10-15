//
//  XVimKeymap.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimKeyStroke.h"

@class XVimKeymapNode;

@interface XVimKeymapContext : NSObject
@property (nonatomic, strong) XVimMutableString* inputKeys;  // All the keys input so far

// substring of inputKeys which can be maps to keys (maximum match).
// This is used when for example "ab" maps to "l" and "abcd" maps to "j".
// In this case when input is "abc", mappedKeys = "ab" and targetKeys = "l"
// And inputKeys = "abc"
// When there is no input for "timeoutlen" it should be treated as "l" + "c" and
// anc "c" must be also taken as mappable key input. (if "c" maps to "l" "abc" results in "ll")
@property (nonatomic, strong) XVimMutableString* lastMappedKeys;
@property (nonatomic, strong) XVimKeymapNode* lastMappedNode;
@property (nonatomic, strong) XVimKeymapNode* node;

- (void)clear;

/**
 * This returns just a diff of inputKeys and lastMappedFromKeys
 **/
- (XVimString*)unmappedKeys;
@end


@interface XVimKeymap : NSObject
/**
 * Create new key mapping
 **/
- (void)map:(XVimString*)keyStrokes to:(NSString*)targetKeyStrokes withRemap:(BOOL)remap;

/**
 * Unmap specified key mapping
 **/
- (void)unmap:(XVimString*)keyStrokes;

/**
 * Clear all the mappings
 **/
- (void)clear;

/**
 * Map "keys" to new key input.
 * Update "context" according to the input "keys" by mapping to the keymap.
 * If the mapping generates fixed mapping(a map which is not ambiguous)
 * this returns new key input and "context" include the information of the mapping.
 * If it is still ambiguous this return nil.
 * If 'fix' flag is set this never returns nil and create new mapping forcefully
 * This may return the same keys as input when there is no mapping or 'fix' is set.
 **/
- (XVimString*)mapKeys:(XVimString*)keys withContext:(XVimKeymapContext*)context forceFix:(BOOL)fix;

- (void)enumerateKeymaps:(void (^)(NSString* mapFrom, NSString* mapTo))block;

@end
