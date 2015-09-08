//
//  IDEApplicationController+XVim.m
//  XVim
//
//  Created by Wojciech Czekalski on 08.09.2015.
//
//

#import "IDEApplicationController+XVim.h"
#import "NSObject+XVimAdditions.h"
#import "XVim.h"

@implementation IDEApplicationController (XVim)

+ (void)xvim_initialize{
    if ([self methodForSelector:@selector(_updateEditorAndNavigateMenusIfNeeded)] == NULL) {
        return;
    }
    
    [self xvim_swizzleInstanceMethod:@selector(_updateEditorAndNavigateMenusIfNeeded) with:@selector(xvim_updateEditorAndNavigateMenusIfNeeded)];
}

- (void)xvim_updateEditorAndNavigateMenusIfNeeded{
    [self xvim_updateEditorAndNavigateMenusIfNeeded];
    
    NSMenu *menu = [[NSApplication sharedApplication] menu];
    
    NSMenuItem *editorMenuItem = [menu itemWithTitle:@"Editor"];
    NSMenuItem *xvimMenuItem = [XVim xvimMenuItem];
    
    if ([[editorMenuItem submenu] itemWithTitle:xvimMenuItem.title] == nil) {
        [[editorMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        [[editorMenuItem submenu] addItem:xvimMenuItem];
    }
}

@end
