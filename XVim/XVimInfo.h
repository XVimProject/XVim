//
//  XVimInfo.h
//  XVim
//
//  Created by Suzuki Shuichiro on 10/17/13.
//
//

/**
 * This class(actually it is just a category) is managing .xviminfo file.
 * .xviminfo is a file to save XVim state (which is just like .viminfo file)
 * Currntly it is implemented as a plist file to save state but 
 * it may be changed to .viminfo format to make good integration between
 * XVim and Vim.
 **/

#import <Foundation/Foundation.h>

@interface XVimInfo : NSObject

- (void)save;

@end
