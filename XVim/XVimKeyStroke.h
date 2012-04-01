//
//  XVimKeyStroke.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVimKeyStroke : NSObject<NSCopying>
+ (void)initKeymaps;
+ (XVimKeyStroke*)fromString:(NSString *)string;
+ (void)fromString:(NSString *)string to:(NSMutableArray *)keystrokest;
+ (XVimKeyStroke*)fromEvent:(NSEvent*)event;
- (NSEvent*)toEvent;
- (NSString*)toSelectorString;
- (SEL)selectorForInstance:(id)target;
- (BOOL)instanceResponds:(id)target;
- (BOOL)classResponds:(Class)class;
- (XVimKeyStroke*)keyStrokeByStrippingModifiers;

@property (nonatomic) unichar key;
@property (nonatomic) int modifierFlags;
@end
