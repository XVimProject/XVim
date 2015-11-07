//
//  IDEEditorArea+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>
#import "IDEEditorArea+XVim.h"
#import "NSObject+XVimAdditions.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "NSObject+ExtraData.h"

static const char *KEY_WINDOW = "xvimwindow";

/**
 * IDEEditorArea is a area including primary editor and assistant editor and debug area (The view right of the navigator)
 * This class hooks IDEEditorArea and does some works.
 * "viewDidInstall" is called when the view setup is done ( as far as I saw the behaviour ).
 * This class has private instance variable named "_editorAreaAutoLayoutView" which is the view
 * contains source code editores and border view between editors and debug area.
 * We insert command line view between editors and debug area.
 *
 * IDEEdiatorArea exists in every Xcode tabs so if you have 4 tabs in a Xcode window there are 4 command line and XVimWindow views we insert.
 */
@implementation IDEEditorArea (XVim)

+ (void)xvim_initialize
{
    if (self == [IDEEditorArea class]) {
        [self xvim_swizzleInstanceMethod:@selector(initWithNibName:bundle:)
                                    with:@selector(xvim_initWithNibName:bundle:)];
        [self xvim_swizzleInstanceMethod:@selector(_setEditorModeViewControllerWithPrimaryEditorContext:)
                                    with:@selector(xvim__setEditorModeViewControllerWithPrimaryEditorContext:)];
    }
}

- (id)xvim_initWithNibName:(NSString *)name bundle:(NSBundle *)bundle{
    id obj = [self xvim_initWithNibName:name bundle:bundle];
    if( obj ){
    //    [self setData:cmd forName:@"CommandLine" ];
    }
    
    return obj;
    
    // I tried to setup cmdline view here but Xcode doesn't allow it.
    // It generates assertion that says "state token is nil".
    // I don't know what state token is but I found that state token is set
    // during the view setup.
    // So I defer to install cmdline until _setEditorModeViewWithController... is called.
    // I have tried several timings 
    // (Still wondering if this is the best place to insatll cmdline)
}

- (XVimWindow *)xvim_window
{
    return objc_getAssociatedObject(self, KEY_WINDOW);
}

- (XVimCommandLine*)xvim_commandline{
    return [self dataForName:@"CommandLine"];
}

- (NSView *)_xvim_editorModeHostView
{
    // The view contains editor and navigation bar(at the top)
    return [ self valueForKey:@"_editorModeHostView"];
}

- (NSView *)_xvim_editorAreaAutoLayoutView
{
    // The view contains editors and border view
    return [ self valueForKey:@"_editorAreaAutoLayoutView"];
}

- (DVTBorderedView *)_xvim_debuggerBarBorderedView
{
    DVTBorderedView *border;

    // The view contains editors and border view
    border = [ self valueForKey:@"_debuggerBarBorderedView"];
    return border;
}

- (void)xvim__setEditorModeViewControllerWithPrimaryEditorContext:(id)arg1{
    
    [self xvim__setEditorModeViewControllerWithPrimaryEditorContext:arg1];
    
    NSView *layoutView = [self _xvim_editorModeHostView];
    if( nil == layoutView){
        return;
    }
    
    NSView* editor = [[layoutView subviews] firstObject];
    if( nil == editor ){
        return;
    }
    
    XVimCommandLine *cmd = [self dataForName:@"CommandLine"];
    if( nil == cmd ){
        cmd = [[XVimCommandLine alloc] init];
        [self setData:cmd forName:@"CommandLine"];
    }
    
    XVimWindow* xvim = self.xvim_window;
    if( nil == xvim ){
        xvim = [[XVimWindow alloc] initWithIDEEditorArea:self];
        objc_setAssociatedObject(self, KEY_WINDOW, xvim, OBJC_ASSOCIATION_RETAIN);
    }
    
    [editor setTranslatesAutoresizingMaskIntoConstraints:NO];
    [cmd setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [layoutView addSubview:cmd];
    
    
    // Same width with the parent
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:editor
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:layoutView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    // editor's left position is same as layoutView
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:editor
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:layoutView
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    // editor fills to top of the layout view
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:editor
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:layoutView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    // Place command at bottom edge
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:cmd
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:layoutView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    // command line width fills the layout view
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:cmd
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:layoutView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:cmd
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:layoutView
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    // Position editor above the command line
    [layoutView addConstraint:[NSLayoutConstraint constraintWithItem:editor
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:cmd
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
    
    
    // Make cmd hegiht small as possible as it can be
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:cmd
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:0];
    
    constraint.priority = 250;
    [layoutView addConstraint:constraint]; 
    
    [self.view setNeedsLayout:YES];
}

@end
