//
//  DVTTextSidebarViewHook.m
//  XVim
//
//  Created by Weijing Liu on 2/15/14.
//
//
#define __XCODE5__

#import "DVTTextSidebarViewHook.h"

#import <AppKit/NSAttributedString.h>
#import <AppKit/NSText.h>

#import "DVTKit.h"
#import "DVTSourceTextViewHook.h"
#import "Hooker.h"
#import "Logger.h"
#import "DVTKit.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "DVTSourceTextView+XVim.h"
#import "XVim.h"

static CGFloat kTextSideBarLineNumberRightPadding = 5.0;

@implementation DVTTextSidebarViewHook

+ (void)hook:(NSString*)method{
    NSString* cls = @"DVTTextSidebarView";
    NSString* thisCls = NSStringFromClass([self class]);
    [Hooker hookClass:cls method:method byClass:thisCls method:method];
    TRACE_LOG(@"%s %@", __func__, method);
}

+ (void)unhook:(NSString*)method{
    NSString* cls = @"DVTTextSidebarView";
    [Hooker unhookClass:cls method:method];
    TRACE_LOG(@"%s %@", __func__, method);
}

+ (void)hook{
    [self hook:
     @"_drawLineNumbersInSidebarRect:"
     @"foldedIndexes:"
     @"count:"
     @"linesToInvert:"
     @"linesToReplace:getParaRectBlock:"];
}

+ (void)unhook{
    [self unhook:
     @"_drawLineNumbersInSidebarRect:"
     @"foldedIndexes:"
     @"count:"
     @"linesToInvert:"
     @"linesToReplace:getParaRectBlock:"];
}

- (void)_drawLineNumbersInSidebarRect:(struct CGRect)arg1
                        foldedIndexes:(unsigned long long *)arg2
                                count:(unsigned long long)arg3
                        linesToInvert:(id)arg4
                       linesToReplace:(id)arg5
                     getParaRectBlock:(id)arg6{
    DVTTextSidebarView *base = (DVTTextSidebarView *)self;
    
    if (XVim.instance.options.relativenumber) {
        for (int i = 0 ; i < arg3 ; ++i) {
            unsigned long long lineNumber = arg2[i];
            [DVTTextSidebarViewHook _drawRelativeNumberForLineNumber:lineNumber
                                                       inTextSidebar:base];
        }
    } else {
        [base _drawLineNumbersInSidebarRect_:arg1
                               foldedIndexes:arg2
                                       count:arg3
                               linesToInvert:arg4
                              linesToReplace:arg5
                            getParaRectBlock:arg6];
    }
}

+ (void)_drawRelativeNumberForLineNumber:(unsigned long long)lineNumber
                           inTextSidebar:(DVTTextSidebarView *)textSidebarView{
    struct CGRect paraRect;
    struct CGRect firstLineRect;
    
    [textSidebarView getParagraphRect:&paraRect
                        firstLineRect:&firstLineRect
                        forLineNumber:lineNumber];
    
    DVTSourceTextView *sourceTextView = [DVTTextSidebarViewHook sourceTextViewForTextSideBarView:textSidebarView];
    long long currentLineNumber = [sourceTextView _currentLineNumber];
    long long relativeLineNumber = llabs(((long long)lineNumber - currentLineNumber));
    NSString *relativeLineNumberString = [@(relativeLineNumber) stringValue];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [textSidebarView lineNumberTextColor],
                                 NSFontAttributeName: [textSidebarView lineNumberFont],
                                 NSParagraphStyleAttributeName: [NSParagraphStyle dvt_paragraphStyleWithAlignment:NSRightTextAlignment]};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:relativeLineNumberString attributes:attributes];
    
    firstLineRect.size.width -= kTextSideBarLineNumberRightPadding;
    [attributedString drawInRect:firstLineRect];
}

+ (DVTSourceTextView *)sourceTextViewForTextSideBarView:(DVTTextSidebarView *)textSidebarView{
    DVTSourceTextView *sourceTextView = textSidebarView.scrollView.documentView;
    return sourceTextView;
}

@end
