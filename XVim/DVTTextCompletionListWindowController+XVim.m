//
//  DVTTextCompletionListWindowController+XVim.m
//  XVim
//
//  Created by Muronaka Hiroaki on 2015/09/27.
//
//

#import "IDEKit.h"
#import "DVTTextCompletionListWindowController+XVim.h"
#import "XVim.h"
#import "XVimRegister.h"

@implementation DVTTextCompletionListWindowController (XVim)

- (BOOL)tryExpandingCompletion
{
    IDEIndexCompletionItem *item = [self _selectedCompletionItem];
   
    [self expandCompletionItem:item];
    
    return NO;
}

-(void)expandCompletionItem:(IDEIndexCompletionItem*)completionItem {
    NSMutableString* tempRepeatRegister = [XVim instance].tempRepeatRegister;
    
    [self expandCompletionItem:completionItem targetRegister:tempRepeatRegister];
    
    XVimRegisterManager* registerManager = [XVim instance].registerManager;
    if( [registerManager isRecording ] ) {
        NSMutableString* registerString = [NSMutableString stringWithString:registerManager.recordingRegister.string];
        [self expandCompletionItem:completionItem targetRegister:registerString];
        [registerManager.recordingRegister setXVimString:registerString];
    }
}

-(void)expandCompletionItem:(IDEIndexCompletionItem*)completionItem targetRegister:(NSMutableString*)targetRegister {

    unichar lastChar = [targetRegister characterAtIndex:targetRegister.length - 1];
    if( [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastChar] ) {
        [targetRegister deleteCharactersInRange:NSMakeRange(targetRegister.length - 1, 1)];
    }
    
// This is a little better if completionText contains "< # code # >".
//    NSRange range = [self rangeOfExpandFromItemName:completionItem.name tempRegister:targetRegister];
//    if( range.location != NSNotFound ) {
//        [targetRegister replaceCharactersInRange:range withString:completionItem.completionText];
//        return;
//    }
    DVTSourceTextView *textView = (DVTSourceTextView *)self.session.textView;
    if(self.session.wordStartLocation == NSNotFound) {
        return;
    }
    
    NSRange wordRange = NSMakeRange(self.session.wordStartLocation, self.session.cursorLocation - self.session.wordStartLocation);
    NSString* word = [textView.string substringWithRange:wordRange];
    NSRange range = [self rangeOfExpandWord:word tempRegister:targetRegister];
    
    if( range.location != NSNotFound ) {
        [targetRegister replaceCharactersInRange:range withString:completionItem.completionText];
    }
}

-(NSRange)rangeOfExpandFromItemName:(NSString*)itemName tempRegister:(NSString*)tempRepeatRegister {
    NSString* lowercaseTempRepeatRegister = [tempRepeatRegister lowercaseString];
    NSString* lowercaseItemName = [itemName lowercaseString];
    
    NSRange result = NSMakeRange(NSNotFound, 0);
    for(NSUInteger i = lowercaseItemName.length; i > 0; i--) {
        NSString* itemSubString = [[lowercaseItemName substringToIndex:i] lowercaseString];
        if( [lowercaseTempRepeatRegister hasSuffix:itemSubString] ) {
            result = NSMakeRange(tempRepeatRegister.length - i, itemSubString.length);
            break;
        }
    }
    return result;
}

-(NSRange)rangeOfExpandWord:(NSString*)word tempRegister:(NSString*)tempRepeatRegister {
    NSString* lowercaseTempRepeatRegister = [tempRepeatRegister lowercaseString];
    NSString* lowercaseWord = [word lowercaseString];
    
    NSRange prevRange = NSMakeRange(NSNotFound, 0);
    for(NSInteger i = (NSInteger)lowercaseTempRepeatRegister.length - 1; i >= 0; i--) {
        NSRange currentRange = NSMakeRange((NSUInteger)i, lowercaseTempRepeatRegister.length - (NSUInteger)i);
        if( ![lowercaseWord hasSuffix:[lowercaseTempRepeatRegister substringWithRange:currentRange]] ) {
            break;
        }
        prevRange = currentRange;
    }
    return prevRange;
}

@end
