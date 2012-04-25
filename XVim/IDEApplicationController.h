//
//  IDEApplicationController.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDEApplicationController : NSObject <NSApplicationDelegate, NSMenuDelegate>
{
    BOOL _haveScannedForPlugins;
    NSDictionary *_extensionIdToMenuDict;
    BOOL _closeKeyEquivalentClosesTab;
    NSString *_documentExtensionIdForCurrentEditorAndNavigateMenus;
    NSString *_currentEditorMenuExtensionId;
    NSString *_currentNavigateMenuExtensionId;
    long long _originalNavigateMenuItemCount;
    NSMenuItem *_shiftedCloseMenuItem;
    NSMenuItem *_shiftedCloseAllMenuItem;
//    IDEOrganizerWindowController *_windowController;
//    IDESourceControlUIHandler *_sourceControlUIHandler;
//    DVTDelayedValidator *_tabStateContextDelayedSaveValidator;
    NSMutableDictionary *_tabStateContextForTabNameMap;
//    id <DVTObservingToken> _hotKeyToEnableFloatingDebuggerToken;
//    id <DVTObservingToken> _lastActiveEditorToken;
//    id <DVTObservingToken> _lastActiveEditorContextToken;
    id _keyBindingSetWillActivateObserver;
    id _keyBindingSetDidActivateObserver;
}

+ (id)sharedAppController;
+ (void)initialize;
@property BOOL haveScannedForPlugins; // @synthesize haveScannedForPlugins=_haveScannedForPlugins;
- (void)_setTabStateContext:(id)arg1 forTabNamed:(id)arg2;
- (id)_tabStateContextForTabNamed:(id)arg1;
- (id)_tabStateContextForTabNameMapByInstantiatingIfNeeded;
- (id)_tabStateContextForTabNameMapFromFilePath:(id)arg1;
- (BOOL)_saveTabStateContextForTabNameMapToFilePath:(id)arg1;
- (void)_updateEditorAndNavigateMenusIfNeeded;
- (void)_pruneNavigateMenu;
- (void)_pruneEditorMenu;
- (id)_navigateMenu;
- (id)_editorMenu;
- (id)_editorForMenuContent;
- (void)_updateUtilitiesMenuIfNeeded;
- (void)_updateEditMenuIfNeeded;
- (id)_utilitiesMenu;
- (id)_editMenu;
- (id)_closeMenuItem;
- (id)_closeCurrentTabMenuItem;
- (id)_fileMenu;
- (id)_cachedMenuForDefinitionExtensionIdentifier:(id)arg1;
- (id)_cachedMenuDefinitionExtensionIdentifiers;
- (void)_setKeyEquivalentForMenuItem:(id)arg1 toIncludeShiftKey:(BOOL)arg2;
- (void)_updateCloseKeyEquivalents;
- (void)_updateCloseKeyEquivalentsIfNeeded;
- (unsigned long long)applicationShouldTerminate:(id)arg1;
- (unsigned long long)_shouldTerminateClosingDocuments;
- (void)menuNeedsUpdate:(id)arg1;
- (void)menuWillOpen:(id)arg1;
- (void)_updateGlobalHotKeyToEnableFloatingDebugger:(id)arg1;
- (void)_currentPreferenceSetChanged;
- (void)_currentPreferenceSetChanged_;
- (void)applicationDidFinishLaunching:(id)arg1;
- (void)_recordStatistics;
- (void)_incrementCountForKey:(id)arg1 in:(id)arg2;
- (void)_handleGetURLEvent:(id)arg1 withReplyEvent:(id)arg2;
- (BOOL)applicationOpenUntitledFile:(id)arg1;
- (void)_setupURLHandling;
- (void)applicationWillFinishLaunching:(id)arg1;
- (BOOL)application:(id)arg1 openFile:(id)arg2;
- (void)application:(id)arg1 openFiles:(id)arg2;
- (BOOL)_openFiles:(id)arg1;
- (void)_terminateAfterPresentingError:(id)arg1;
- (id)init;
- (void)forwardInvocation:(id)arg1;
- (id)methodSignatureForSelector:(SEL)arg1;
- (void)__dummyActionMethod:(id)arg1;
- (BOOL)validateUserInterfaceItem:(id)arg1;
- (BOOL)validateToolbarItem:(id)arg1;
- (BOOL)validateMenuItem:(id)arg1;
- (BOOL)respondsToSelector:(SEL)arg1;
- (id)_targetForAction:(SEL)arg1;


@end
