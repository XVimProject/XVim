//
//  XVimYunkedText.h
//  XVim
//
//  Created by Suzuki Shuichiro on 11/10/12.
//
//

/**
 * This class represents text in XVim.
 * The difference between XVimText and NSString is that
 * XVimText supports block/line text to hold.
 * This is usually used in yanked text.
 * When you yank something and put it somewhere 
 * how the text edited depends on yanked text type(character/block/line)
 **/

#import <Foundation/Foundation.h>


@interface XVimText : NSObject<NSCopying>
@property(readonly) NSString* string; // This is reference to the first object in "strings"

/**
 * Append string
 **/
- (void)appendString:(NSString*)string;

/**
 * Clear XVimText content.
 **/
- (void)clear;
@end
