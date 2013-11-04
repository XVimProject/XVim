//
//  XVimHighlight.h
//  XVim
//
//  Created by Suzuki Shuichiro on 11/3/13.
//
//

/**
 * The classes here represents highlight infomation in Vim
 * Vim manages highlight color by "highlight groups"
 * Highlight group has a name for the group such ash "Search"
 * "Search" highlight group has a multiple attributes like 'guifg', 'guibg'
 * Each attributes replesents actual color of the text or background of the highlight group.
 * "Search" highglihg group is used when drawing search result text.
 *
 * Vim has many predefined highlight groups but currently XVim only supports "Search" and its attribute "guibg"
 *
 * The class XVimHighlightGroup represents one group which has 'name' and multiple attributes.
 * The clsss XVimHighlightGroups manages multiple highlight groups. (Currently have only one group for "Search" thogugh)
 *
 * XVimHighlightGroup has 'guifg' attribute too but it is not used at the moment
 *
 * See also ':help highlight' in Vim
 **/
#import <Foundation/Foundation.h>

// Must be copiable
@interface XVimHighlightGroup : NSObject<NSCopying>
@property(copy) NSColor*  guifg;
@property(copy) NSColor*  guibg;

+ (id)highlightWithGuifg:(NSColor*)guifg guibg:(NSColor*)guibg;
- (id)initWithGuifg:(NSColor*)guifg guibg:(NSColor*)guibg;
- (id)copyWithZone:(NSZone *)zone;
- (void)setArg:(NSString*)arg forKey:(NSString*)key;
@end

// Highlight group manager
@interface XVimHighlightGroups : NSObject
- (void)setHighlightGroupForName:(NSString*)name key:(NSString*)key arg:(NSString*)arg;
- (XVimHighlightGroup*)highlightGroup:(NSString*)name;
@end
