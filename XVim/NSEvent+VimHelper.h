//
//  NSEvent+VimHelper.h
//  XVim
//
//  Created by Marlon Andrade on 08/27/2012.
//
//

#import <Cocoa/Cocoa.h>

@interface NSEvent (VimHelper)

- (unichar)unmodifiedKeyCode;
- (unichar)modifiedKeyCode;
    
@end
