//
//  DVTTextSidebarViewHook.m
//  XVim
//
//  Created by Weijing Liu on 2/15/14.
//
//
#define __XCODE5__

#import "DVTTextSidebarView+XVim.h"

#import <AppKit/NSAttributedString.h>
#import <AppKit/NSText.h>

#import "DVTKit.h"
#import "Logger.h"
#import "DVTKit.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "DVTSourceTextView+XVim.h"
#import "NSObject+XVimAdditions.h"
#import "XVim.h"

static CGFloat kTextSideBarLineNumberRightPadding = 5.0;

@implementation DVTTextSidebarView(XVim)
+ (void)xvim_initialize{
#ifdef XVIM_XCODE8
    [self xvim_swizzleInstanceMethod:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToHighlight:linesToReplace:textView:getParaRectBlock:)
                                with:@selector(xvim__drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToHighlight:linesToReplace:textView:getParaRectBlock:)];
#else

    [self xvim_swizzleInstanceMethod:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)
                                with:@selector(xvim__drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)];
#endif
}

// Xcode 8
- (void)xvim__drawLineNumbersInSidebarRect:(CGRect)arg1
                             foldedIndexes:(NSUInteger *)arg2
                                     count:(NSUInteger)arg3
                             linesToInvert:(id)arg4
                          linesToHighlight:(id)arg5
                            linesToReplace:(id)arg6
                                  textView:(id)arg7
                          getParaRectBlock:(GetParaBlock)arg8
{
        if (XVim.instance.options.relativenumber) {
                for (NSUInteger i = 0 ; i < arg3 ; ++i) {
                        unsigned long long lineNumber = arg2[i];
                        [self xvim_drawRelativeNumberForLineNumber:lineNumber];
                }
        }
        else {
                [self xvim__drawLineNumbersInSidebarRect:(CGRect)arg1
                                           foldedIndexes:(NSUInteger *)arg2
                                                   count:(NSUInteger)arg3
                                           linesToInvert:(id)arg4
                                        linesToHighlight:(id)arg5
                                          linesToReplace:(id)arg6
                                                textView:(id)arg7
                                        getParaRectBlock:(GetParaBlock)arg8];
        }
}

// Pre-Xcode 8
- (void)xvim__drawLineNumbersInSidebarRect:(struct CGRect)arg1
                        foldedIndexes:(unsigned long long *)arg2
                                count:(unsigned long long)arg3
                        linesToInvert:(id)arg4
                       linesToReplace:(id)arg5
                     getParaRectBlock:(id)arg6
{
    
    if (XVim.instance.options.relativenumber) {
        for (NSUInteger i = 0 ; i < arg3 ; ++i) {
            unsigned long long lineNumber = arg2[i];
            [self xvim_drawRelativeNumberForLineNumber:lineNumber];
        }
    } else {
        [self xvim__drawLineNumbersInSidebarRect:arg1
                                    foldedIndexes:arg2
                                            count:arg3
                                    linesToInvert:arg4
                                   linesToReplace:arg5
                                 getParaRectBlock:arg6];
    }
}

- (void)xvim_drawRelativeNumberForLineNumber:(NSUInteger)lineNumber
{
    struct CGRect paraRect;
    struct CGRect firstLineRect;
        
    [self getParagraphRect:&paraRect firstLineRect:&firstLineRect forLineNumber:lineNumber];
    
    DVTSourceTextView *sourceTextView = self.scrollView.documentView;
    NSUInteger relativeLineNumber = (NSUInteger)llabs(((long long)lineNumber - sourceTextView._currentLineNumber));
    BOOL drawLineIsCurrentLine = (XVim.instance.options.number && relativeLineNumber == 0);
    NSUInteger drawLineNumber =  drawLineIsCurrentLine ? lineNumber : relativeLineNumber;
    NSString *relativeLineNumberString = [@(drawLineNumber) stringValue];
    NSColor *drawLineNumberColor = drawLineIsCurrentLine ? [NSColor colorWithWhite:0.8 alpha:1.0] : [self lineNumberTextColor];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName: drawLineNumberColor,
                                 NSFontAttributeName: [self lineNumberFont],
                                 NSParagraphStyleAttributeName: [NSParagraphStyle dvt_paragraphStyleWithAlignment:NSRightTextAlignment]};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:relativeLineNumberString attributes:attributes];
    
    firstLineRect.size.width -= kTextSideBarLineNumberRightPadding;
    [attributedString drawInRect:firstLineRect];
}

@end
