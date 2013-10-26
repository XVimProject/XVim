//
//  XVimTestCase.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import "Logger.h"
#import "XVimTestCase.h"
#import "IDEKit.h"
#import "XVimUtil.h"
#import "DVTSourceTextView+XVim.h"
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
#import "NSTextView+VimOperation.h"

@implementation XVimTestCase
+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                    initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
{
    return [self testCaseWithInitialText:it
                             initialRange:ir
                                    input:in
                             expectedText:et
                            expectedRange:er
                              description:in];
}

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                    initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                            description:(NSString *)desc
{
    XVimTestCase* test = [[[XVimTestCase alloc] init] autorelease];
    test.initialText = it;
    test.initialRange = ir;
    test.input = in;
    test.expectedText = et;
    test.expectedRange = er;
    test.message = @"";
    if( nil != desc ){
        test.description = desc;
    }else{
        test.description = in;
    }
    
    return test;
}

- (void)dealloc{
    self.initialText = nil;
    self.input = nil;
    self.expectedText = nil;
    self.message = nil;
    [super dealloc];
}

- (void)setUp{
    [[[XVimLastActiveSourceView() xvimWindow] sourceView] xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [XVimLastActiveSourceView() setString:self.initialText];
    [XVimLastActiveSourceView() setSelectedRange:self.initialRange];
}

- (BOOL)assert{
    if( ![self.expectedText isEqualToString:[XVimLastActiveSourceView() string]] ){
        self.message = [NSString stringWithFormat:@"Result text is different from expected text.\n\nResult Text:\n%@\n\nExpected Text:\n%@\n", [XVimLastActiveSourceView() string], self.expectedText];
        return NO;
    }
    
    NSRange resultRange = [XVimLastActiveSourceView() selectedRange];
    if( self.expectedRange.location != resultRange.location ||
        self.expectedRange.length   != resultRange.length
       ){
        self.message = [NSString stringWithFormat:@"Result range(%lu,%lu) is different from expected range(%lu,%lu)", resultRange.location, resultRange.length, self.expectedRange.location, (unsigned long)self.expectedRange.length];
        return NO;
    }
    return YES;
}

- (void)executeInput:(NSString*)notation{
    NSInteger num = [[XVimLastActiveWindowController() window] windowNumber];
    NSGraphicsContext* context = [[XVimLastActiveWindowController() window] graphicsContext];
    NSArray* strokes = XVimKeyStrokesFromKeyNotation(notation);
    for( XVimKeyStroke* stroke in strokes ){
        NSEvent* event = [stroke toEventwithWindowNumber:num context:context];
        [[IDEApplication sharedApplication] sendEvent:event];
    }
}

- (void)tearDown{
    [self executeInput:@"<ESC>"];
    [self executeInput:@":mapclear<CR>"];
    [XVimLastActiveSourceView() display];
}

- (void)executeInput{
    [self executeInput:self.input];
}

- (BOOL)run{
    [self setUp];
    [self executeInput];
    self.success = [self assert];
    [self tearDown];
    return self.success;
}
@end
