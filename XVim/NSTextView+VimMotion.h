//
//  NSTextView+VimMotion.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"

typedef enum{
    LEFT_RIGHT_WRAP,
    LEFT_RIGHT_NOWRAP
} MOTION_OPTION;

@interface NSTextView (VimMotion)
- (NSUInteger)nextNewline;
- (NSUInteger)prevNewline;
- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to;
@end
