//
//  NSEvent+VimHelper.m
//  XVim
//
//  Created by Marlon Andrade on 08/27/2012.
//
//

#import "NSEvent+VimHelper.h"

@implementation NSEvent (VimHelper)

- (unichar)unmodifiedKeyCode {
    NSString *charactersIgnoringModifiers = [self charactersIgnoringModifiers];
    return charactersIgnoringModifiers.length > 0 ? [charactersIgnoringModifiers characterAtIndex:0] : 0;
}

- (unichar)modifiedKeyCode {
    NSString *characters = [self characters];
    return characters.length > 0 ? [characters characterAtIndex:0] : [self unmodifiedKeyCode];
}

@end
