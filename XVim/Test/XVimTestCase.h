//
//  XVimTestCase.h
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import <Foundation/Foundation.h>

#define XVimMakeTestCase(initText, initRangeLoc, initRangeLen, inputText , expcText, expcRangeLoc, expcRangeLen) \
        [XVimTestCase testCaseWithInitialText:initText \
                        initialRange:NSMakeRange(initRangeLoc, initRangeLen) \
                        input:inputText \
                        expectedText:expcText \
                        expectedRange:NSMakeRange(expcRangeLoc, expcRangeLen)]

#define XVimMakeTestCaseWithDesc(initText, initRangeLoc, initRangeLen, inputText , expcText, expcRangeLoc, expcRangeLen, desc) \
        [XVimTestCase testCaseWithInitialText:initText \
                        initialRange:NSMakeRange(initRangeLoc, initRangeLen) \
                        input:inputText \
                        expectedText:expcText \
                        expectedRange:NSMakeRange(expcRangeLoc, expcRangeLen) \
                        description:desc]

@interface XVimTestCase : NSObject
@property(strong) NSString* initialText;
@property         NSRange  initialRange;
@property(strong) NSString* input;
@property(strong) NSString* expectedText;
@property         NSRange   expectedRange;
@property(strong) NSString* description;
@property(strong) NSString* message;
@property         BOOL      success;


+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                            initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                             description:(NSString*)desc;

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                            initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                            expectedRange:(NSRange)er;

- (BOOL)run;
@end
