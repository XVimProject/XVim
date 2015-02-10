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
                        expectedRange:NSMakeRange(expcRangeLoc, expcRangeLen) \
                        file:[NSString stringWithUTF8String:__FILE__] \
                        line:__LINE__]

#define XVimMakeTestCaseWithDesc(initText, initRangeLoc, initRangeLen, inputText , expcText, expcRangeLoc, expcRangeLen, desc) \
        [XVimTestCase testCaseWithInitialText:initText \
                        initialRange:NSMakeRange(initRangeLoc, initRangeLen) \
                        input:inputText \
                        expectedText:expcText \
                        expectedRange:NSMakeRange(expcRangeLoc, expcRangeLen) \
                        description:desc \
                        file:[NSString stringWithUTF8String:__FILE__] \
                        line:__LINE__]

@interface XVimTestCase : NSObject
@property(strong) NSString* initialText;
@property         NSRange  initialRange;
@property(strong) NSString* input;
@property(strong) NSString* expectedText;
@property         NSRange   expectedRange;
@property(strong) NSString* desc; // description is declared in NSObject and readonly.
@property(strong) NSString* message;
@property         BOOL      success;
@property         NSString* file;
@property         NSUInteger line;


+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                            initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                             description:(NSString*)desc
                                    file:(NSString*)file
                                    line:(NSUInteger)line;

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                            initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                            expectedRange:(NSRange)er
                                    file:(NSString*)file
                                    line:(NSUInteger)line;

- (BOOL)run;
@end
