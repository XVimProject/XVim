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
    [super dealloc];
}

- (BOOL)run{
    [XVimLastActiveSourceView() setString:self.initialText];
    [XVimLastActiveSourceView() setSelectedRange:self.initialRange];
    
    NSInteger num = [[IDEWorkspaceWindow lastActiveWorkspaceWindow] windowNumber];
    NSGraphicsContext* context = [[IDEWorkspaceWindow lastActiveWorkspaceWindow] graphicsContext];
    for( NSUInteger i = 0 ; i < self.input.length; i++ ){
        unichar c = [self.input characterAtIndex:i];
        NSEvent* event = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0,0) modifierFlags:0 timestamp:0 windowNumber:num context:context characters:[NSString stringWithFormat:@"%C",c] charactersIgnoringModifiers:[NSString stringWithFormat:@"%C",c] isARepeat:NO keyCode:0];
        [[IDEApplication sharedApplication] sendEvent:event];
    }

    // Check expected state
    
    if( ![self.expectedText isEqualToString:[XVimLastActiveSourceView() string]] ){
        DEBUG_LOG(@"Test Failed : %@", self.description);
        DEBUG_LOG(@"Result   Text : %@", [XVimLastActiveSourceView() string]);
        DEBUG_LOG(@"Expected Text : %@", self.expectedText);
        return NO;
    }
    
    NSRange resultRange = [XVimLastActiveSourceView() selectedRange];
    if( self.expectedRange.location != resultRange.location ||
        self.expectedRange.length   != resultRange.length
       ){
        DEBUG_LOG(@"Test Failed : %@", self.description);
        DEBUG_LOG(@"Result   Range : (%d,%d)", resultRange.location, resultRange.length );
        DEBUG_LOG(@"Expected Range : (%d,%d)", self.expectedRange.location, self.expectedRange.length);
        return NO;
    }
    return YES;
}
@end
