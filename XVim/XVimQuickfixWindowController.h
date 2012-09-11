//
//  XVimQuickfixWindowController.h
//  XVim
//
//  Created by Patrick on 9/8/12.
//
//

#import <Cocoa/Cocoa.h>

@interface XVimQuickfixWindowController : NSWindowController{
    IBOutlet NSTextView* quickfixWindow;
}
@property (strong) NSTextView* quickfixWindow;
@end
