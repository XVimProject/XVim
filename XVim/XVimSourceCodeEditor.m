//
//  XVimSourceCodeEditor.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimSourceCodeEditor.h"
#import "IDESourceCodeEditor.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVim.h"

@implementation XVimSourceCodeEditor

+ (void) hook
{
    Class delegate = NSClassFromString(@"IDESourceCodeEditor");
	[Hooker hookMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) 
			   ofClass:delegate 
			withMethod:class_getInstanceMethod([self class], @selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)) 
   keepingOriginalWith:@selector(textView_:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
    
	[Hooker hookMethod:@selector(initWithNibName:bundle:document:) 
			   ofClass:delegate 
			withMethod:class_getInstanceMethod([self class], @selector(initWithNibName:bundle:document:)) 
   keepingOriginalWith:@selector(initWithNibName_:bundle:document:)];
}

- (NSArray*) textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    // It seems that original IDESourceCodeEditor does not implement this delegate method.
    // So if we try to call original method it causes exception.
    
    // What we do here is to restrict cursor position when its not insert mode
    /*
	 NSTextView* view = textView; // DVTSourceTextView
	 
	 XVim* xvim = [view viewWithTag:XVIM_TAG];
	 if( nil != view ){
	 if( xvim.mode != MODE_INSERT ){
	 NSRange r = [[newSelectedCharRanges objectAtIndex:0] rangeValue];
	 if( ![view isValidCursorPosition:r.location] ){
	 NSValue* val;
	 if( r.length != 0 ){
	 val = [NSValue valueWithRange:NSMakeRange(r.location-1, r.length+1)];
	 }else{
	 val = [NSValue valueWithRange:NSMakeRange(r.location-1, r.length)]; // same as (r.locatio-1, 0)
	 }
	 NSMutableArray* ary = [NSMutableArray arrayWithObject:val];
	 return [ary arrayByAddingObjectsFromArray:[newSelectedCharRanges subarrayWithRange:NSMakeRange(1, [newSelectedCharRanges count]-1)]];
	 }
	 }
	 }
     */
    return newSelectedCharRanges;
}

- (id)initWithNibName:(NSString*)nibName bundle:(NSBundle*)nibBundle document:(NSDocument*)nibDocument{
    TRACE_LOG(@"nibName: %@ nibBundle: %@ nibDocument: %@", nibName, nibBundle, nibDocument);

	IDESourceCodeEditor *editor = (IDESourceCodeEditor*)self;
    [editor initWithNibName_:nibName bundle:nibBundle document:nibDocument];
    TRACE_LOG(@"editor: %@", editor);

    XVim* xvim = [[editor view] viewWithTag:XVIM_TAG];
    xvim.editor = (XVimSourceCodeEditor*)editor;

    return (id)editor;
}

@end