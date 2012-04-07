//
//  XVimCommandField.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/29/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
typedef enum {
    ASKING_OPTION_NONE = 0x00,
    ACCEPT_ONE_LETTER,
}ASKING_OPTION;

@protocol XVimCommandFieldDelegate
- (BOOL)commandCanceled;
- (BOOL)commandFixed:(NSString*)cmd;
@end

@interface XVimCommandField : NSTextView{
    id <XVimCommandFieldDelegate> delegate;
}
@property (retain, nonatomic) id <XVimCommandFieldDelegate> delegate;

- (void)answered:(id)sender;
- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt;

@end
