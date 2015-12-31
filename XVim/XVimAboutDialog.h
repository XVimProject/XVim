//
//  XVimAboutDialog.h
//  XVim
//
//  Created by Suzuki Shuichiro on 12/31/15.
//
//

#import <Cocoa/Cocoa.h>

//  is replaced by the commit hash at 'run script' build phase
#define GIT_REVISION_STRING 

@interface XVimAboutDialog : NSWindowController
@property (weak) IBOutlet NSButton *reportBugButton;
@property (unsafe_unretained) IBOutlet NSTextView *infoTextView;
- (IBAction)onReportBug:(id)sender;

@end
