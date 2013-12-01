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
    
@interface NSEvent(XVimKeyStroke)
- (XVimKeyStroke*)toXVimKeyStroke;
- (XVimString*)toXVimString;
@end

@interface XVimKeyStroke : NSObject<NSCopying>
@property unichar character;
@property unsigned char modifier;
@property (nonatomic, readonly) BOOL isNumeric;
@property (nonatomic, readonly) BOOL isPrintable;

- (id)initWithCharacter:(unichar)c modifier:(unsigned char)mod;

- (XVimString*)xvimString;

// Generates an event from this key stroke
- (NSEvent*)toEventwithWindowNumber:(NSInteger)num context:(NSGraphicsContext*)context;

// Creates a human-readable string
- (NSString*)keyNotation;

// Returns the selector for this object
- (SEL)selector;

// Following methods are for to be a key in NSDictionary
- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;
- (id)copyWithZone:(NSZone *)zone;

@end