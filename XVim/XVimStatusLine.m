//
//  XVimStatusLine.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimStatusLine.h"
#import "DVTKit.h"
#import "IDEKit.h"
#import "Logger.h"
#import "NSInsetTextView.h"
#import <objc/runtime.h>
#import "XVim.h"
#import "XVimOptions.h"

@implementation XVimLaststatusTransformer 
+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (value == nil) return nil;
    
    NSInteger laststatus = [value integerValue];
    
    // TODO: Handle "1" case correctly ("only if there are at least two window" case)
    if( laststatus == 2 ){
        return [NSNumber numberWithBool:NO]; // HIDDEN = NO
    }
    return [NSNumber numberWithBool:YES]; // HIDDEN = YES
}
@end

@implementation XVimStatusLine

- (NSSize)intrinsicContentSize{
    if( self.hidden ){
        return NSMakeSize(NSViewNoInstrinsicMetric, 0.0);
    }else{
        return [super intrinsicContentSize];
    }
}

- (void)setHidden:(BOOL)hidden{
    [super setHidden:hidden];
    [self invalidateIntrinsicContentSize];
}

- (id)initWithString:(NSString *)str{
    self = [super init];
    if (self) {
        DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
        if( nil != theme ){
            NSFont *sourceFont = [theme sourcePlainTextFont];
            [self setFont:sourceFont];
            [self setBackgroundColor:[theme sourceTextSidebarBackgroundColor]];
        }
        if( nil != str ){
            [self setStringValue:str];
        }
        [self setEditable:NO];
        [self setSelectable:YES];
        [self setBordered:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontAndColorSourceTextSettingsChanged:) name:@"DVTFontAndColorSourceTextSettingsChangedNotification" object:nil];
    }
    
    return self;
}

- (void)dealloc{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DVTFontAndColorSourceTextSettingsChangedNotification" object:nil];
}

- (void)fontAndColorSourceTextSettingsChanged:(NSNotification*)notification{
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
    if( nil != theme ){
        [self setFont:[theme sourcePlainTextFont]];
        [self setBackgroundColor:[theme sourceTextSidebarBackgroundColor]];
    }
}

@end
