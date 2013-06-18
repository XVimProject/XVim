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

@interface XVimKeymapContext : NSObject {
}
@property (nonatomic, retain) XVimMutableString* inputKeys;  // All the keys input so far
@property (nonatomic, retain) XVimMutableString* lastMappedKeys; // substring of inputKeys which can be maps to keys (maximum match).
                                                           // This is used when for example "ab" maps to "l" and "abcd" maps to "j".
                                                           // In this case when input is "abc", mappedKeys = "ab" and targetKeys = "l"
                                                           // And inputKeys = "abc"
                                                           // When there is no input for "timeoutlen" it should be treated as "l" + "c" and
                                                           // anc "c" must be also taken as mappable key input. (if "c" maps to "l" "abc" results in "ll")
@property (nonatomic, retain) XVimKeymapNode* lastMappedNode;
@property (nonatomic, retain) XVimKeymapNode* node;
- (void)clear;

/**
 * This returns just a diff of inputKeys and lastMappedFromKeys
 **/
- (XVimString*)unmappedKeys;
@end


@interface XVimKeymap : NSObject
- (void)map:(XVimString*)keyStrokes to:(NSString*)targetKeyStrokes withRemap:(BOOL)remap;
- (void)unmap:(XVimString*)keyStrokes;
- (void)clear;

/**
 * Update "context" according to the input "keys" by mapping to the keymap.
 * If the mapping generates fixed mapping(a map which is not ambiguous)
 * this returns true and "context" include the information of the map.
 * You have to handle "unmapedKesy" of the context properly.
 **/
- (XVimString*)mapKeys:(XVimString*)keys withContext:(XVimKeymapContext*)context forceFix:(BOOL)fix;
@end
