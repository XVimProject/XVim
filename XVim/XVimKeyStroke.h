//
//  XVimKeyStroke.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimKeyStroke;
typedef NSString XVimString;
typedef NSMutableString XVimMutableString;

// Helper Functions
XVimString* XVimStringFromKeyNotation(NSString* notation);
XVimString* XVimStringFromKeyStrokes(NSArray* strokes);
NSArray* XVimKeyStrokesFromXVimString(XVimString* string);
NSArray* XVimKeyStrokesFromKeyNotation(NSString* notation);
NSString* XVimKeyNotationFromXVimString(XVimString* string);
BOOL isPrintable(unichar c);
    
@interface NSEvent(XVimKeyStroke)
- (XVimKeyStroke*)toXVimKeyStroke;
- (XVimString*)toXVimString;
@end

@interface XVimKeyStroke : NSObject<NSCopying>
@property unichar character;
@property unsigned char modifier;
@property (nonatomic, readonly) BOOL isNumeric;

- (id)initWithCharacter:(unichar)c modifier:(unsigned char)mod;

- (XVimString*)xvimString;

// Generates an event from this key stroke
- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(NSGraphicsContext*)context;

// Creates the selector string from this key stroke
- (NSString*)toSelectorString;

// Creates a human-readable string
- (NSString*)keyNotation;

// Returns the selector for this object
- (SEL)selector;

// Returns a selector for the target for this key stroke if one exists
- (SEL)selectorForInstance:(id)target;

// Returns YES if the instance responds to this key stroke
- (BOOL)instanceResponds:(id)target;

// Returns YES if the class' instances respond to this key stroke
- (BOOL)classResponds:(Class)class;

// Returns YES if the class implements this method and does so different to its superclass
- (BOOL)classImplements:(Class)class;

// Following methods are for to be a key in NSDictionary
- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;
- (id)copyWithZone:(NSZone *)zone;

@end