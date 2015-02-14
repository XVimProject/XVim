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
    [self xvim_swizzleInstanceMethod:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:) with:@selector(xvim__drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)];

}
- (void)xvim__drawLineNumbersInSidebarRect:(struct CGRect)arg1
                        foldedIndexes:(unsigned long long *)arg2
                                count:(unsigned long long)arg3
                        linesToInvert:(id)arg4
                       linesToReplace:(id)arg5
                     getParaRectBlock:(id)arg6{
    
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

- (void)xvim_drawRelativeNumberForLineNumber:(unsigned long long)lineNumber{
       
    struct CGRect paraRect;
    struct CGRect firstLineRect;
    
    [self getParagraphRect:&paraRect firstLineRect:&firstLineRect forLineNumber:lineNumber];
    
    DVTSourceTextView *sourceTextView = self.scrollView.documentView;
    long long currentLineNumber = [sourceTextView _currentLineNumber];
    long long relativeLineNumber = llabs(((long long)lineNumber - currentLineNumber));
    if (XVim.instance.options.number && relativeLineNumber == 0) relativeLineNumber = (long long)lineNumber;
    NSString *relativeLineNumberString = [@(relativeLineNumber) stringValue];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [self lineNumberTextColor],
                                 NSFontAttributeName: [self lineNumberFont],
                                 NSParagraphStyleAttributeName: [NSParagraphStyle dvt_paragraphStyleWithAlignment:NSRightTextAlignment]};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:relativeLineNumberString attributes:attributes];
    
    firstLineRect.size.width -= kTextSideBarLineNumberRightPadding;
    [attributedString drawInRect:firstLineRect];
}

@end
