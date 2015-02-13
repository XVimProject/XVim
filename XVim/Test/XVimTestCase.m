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
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
#import "NSTextView+VimOperation.h"
#import "DVTSourceTextView+XVim.h"

@implementation XVimTestCase
+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                    initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                                    file:(NSString *)file
                                    line:(NSUInteger)line
{
    return [self testCaseWithInitialText:it
                             initialRange:ir
                                    input:in
                             expectedText:et
                            expectedRange:er
                              description:in
                                     file:file
                                     line:line];
}

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                    initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                            description:(NSString *)desc
                                    file:(NSString *)file
                                    line:(NSUInteger)line

{
    XVimTestCase* test = [[XVimTestCase alloc] init];
    test.initialText = it;
    test.initialRange = ir;
    test.input = in;
    test.expectedText = et;
    test.expectedRange = er;
    test.message = @"";
    if( nil != desc ){
        test.desc = desc;
    }else{
        test.desc = in;
    }
    test.file = file;
    test.line = line;
    
    return test;
}


- (void)setUp{
    [[[XVimLastActiveSourceView() xvim_window] sourceView] xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [XVimLastActiveSourceView() setString:self.initialText];
    [XVimLastActiveSourceView() setSelectedRange:self.initialRange];
}

- (BOOL)assert{
    if( ![self.expectedText isEqualToString:[XVimLastActiveSourceView() string]] ){
        self.message = [NSString stringWithFormat:@"Result text is different from expected text.\n\nResult Text:\n%@\n\nExpected Text:\n%@ [%@:%ld]\n", [XVimLastActiveSourceView() string], self.expectedText,self.file, self.line];
        return NO;
    }
    
    NSRange resultRange = [XVimLastActiveSourceView() selectedRange];
    if( self.expectedRange.location != resultRange.location ||
        self.expectedRange.length   != resultRange.length
       ){
        self.message = [NSString stringWithFormat:@"Result range(%lu,%lu) is different from expected range(%lu,%lu) [%@:%ld]", resultRange.location, resultRange.length, self.expectedRange.location, (unsigned long)self.expectedRange.length, self.file, self.line];
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
        
        // Tells NSUndoManager to end grouping (Little hacky)
        // This is because the loop here emulates NSApplication's run loop.
        // To make NSUndoManager work properly we have to call this after each event
        [NSUndoManager performSelector:@selector(_endTopLevelGroupings)];
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
