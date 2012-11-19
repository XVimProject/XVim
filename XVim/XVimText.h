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

typedef enum{
    TEXT_TYPE_CHARACTERS,
    TEXT_TYPE_BLOCK,
    TEXT_TYPE_LINES
}TEXT_TYPE;

@interface XVimText : NSObject
@property TEXT_TYPE type;
@property(readonly) NSMutableArray* strings;
@property(readonly) NSString* string; // This is reference to the first object in "strings"

/**
 * Append string to first object of the "strings" array.
 **/
- (void)appendString:(NSString*)string;

/**
 * Clear XVimText content.
 **/
- (void)clear;
@end
