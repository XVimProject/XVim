//
//  XVimKeyStroke.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVimKeyStroke : NSObject<NSCopying>

// Call on startup to initialise static data
+ (void)initKeymaps;

/**
 * Returns all possible mapping options from an event
 * Eg. S-n would return S-n, S-N and N.
 * The primary key stroke is returned (in the above case, N is returned)
 * This is to be used in case a mapping is not found.
**/
+ (XVimKeyStroke*)keyStrokeOptionsFromEvent:(NSEvent*)event into:(NSMutableArray*)options;

// Parses a string into a key stroke
+ (XVimKeyStroke*)fromString:(NSString *)string;

// Parses a string into an array of key strokes
+ (void)fromString:(NSString *)string to:(NSMutableArray *)keystrokes;

- (id)initWithKeyCode:(unichar)keyCode
		modifierFlags:(NSUInteger)modifierFlags;

// Constructs a key stroke from an event
- (id)initWithEvent:(NSEvent*)event 
				keyCode:(unichar)keyCode 
		  modifierFlags:(NSUInteger)modifierFlags;

// Generates an event from this key stroke
- (NSEvent*)toEvent;

// Creates the selector string from this key stroke
- (NSString*)toSelectorString;

// Creates a human-readable string
- (NSString*)toString;

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

@property (nonatomic) unichar keyCode;
@property (nonatomic) NSUInteger modifierFlags;
@property (nonatomic, readonly) BOOL isNumeric;
@end