//
//  XVimTest.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import "XVimTester.h"
#import "XVimTestCase.h"
#import <objc/runtime.h>
#import "Logger.h"
#import "IDEKit.h"
#import "XVimKeyStroke.h"
#import "XVimUtil.h"


@implementation XVimTester

- (id)init{
    if( self = [super init] ){
        self.testCases = [[NSMutableArray alloc] init];
        unsigned int count = 0;
        Method* m = 0;
        m = class_copyMethodList([XVimTester class],  &count);
        for( unsigned int i = 0 ; i < count; i++ ){
            SEL sel = method_getName(m[i]);
            TRACE_LOG(@"%@", NSStringFromSelector(sel) );
            if( [NSStringFromSelector(sel) hasSuffix:@"_testcases"] ){
                [self.testCases addObjectsFromArray:[self performSelector:sel]];
            }
        }
    }
    return self;
}

- (void)dealloc{
    self.testCases = nil;
    [super dealloc];
}

- (void)runTest{
    // Create Test Cases
    NSArray* testArray = self.testCases;
    
    // Alert Dialog to confirm current text will be deleted.
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Make it sure that a source test view has a focus now.\r Running test deletes text in current source text view. Proceed?"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSInteger b = [alert runModal];
    
    // Run test for all the cases
    if( b == NSAlertFirstButtonReturn ){
        // test each
        for( NSUInteger i = 0; i < testArray.count; i++ ){
            [(XVimTestCase*)[testArray objectAtIndex:i] run];
        }
    }
    
    // Setup Talbe view to show result
    NSTableView* tableView= [[[NSTableView alloc] init] autorelease];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
   
    // Create Columns
    NSTableColumn* column1 = [[NSTableColumn alloc] initWithIdentifier:@"Description" ];
    [column1.headerCell setStringValue:@"Description"];
    NSTableColumn* column2 = [[NSTableColumn alloc] initWithIdentifier:@"Pass/Fail" ];
    [column2.headerCell setStringValue:@"Pass/Fail"];
    NSTableColumn* column3 = [[NSTableColumn alloc] initWithIdentifier:@"Message" ];
    [column3.headerCell setStringValue:@"Message"];
    [column3 setWidth:500.0];
    
    [tableView addTableColumn:column1];
    [tableView addTableColumn:column2];
    [tableView addTableColumn:column3];
    [tableView setAllowsMultipleSelection:YES];
    [tableView reloadData];
    
    // Setup the table view into scroll view
    NSScrollView* scroll = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,600,300)] autorelease];
    [scroll setDocumentView:tableView];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:YES];
    
    // Show it as a modal
    alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Result"];
    [alert setAccessoryView:scroll];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return (NSInteger)[self.testCases count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    if( [aTableColumn.identifier isEqualToString:@"Description"] ){
        return [(XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)rowIndex] description];
    }else if( [aTableColumn.identifier isEqualToString:@"Pass/Fail"] ){
        return ((XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)rowIndex]).success ? @"Pass" : @"Fail";
    }else if( [aTableColumn.identifier isEqualToString:@"Message"] ){
        return ((XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)rowIndex]).message;
    }
    return nil;
}

- (float)heightForString:(NSString*)myString withFont:(NSFont*)myFont withWidth:(float)myWidth{
    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:myString] autorelease];
    NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(myWidth, FLT_MAX)] autorelease];
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textStorage addAttribute:NSFontAttributeName value:myFont
                        range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager
            usedRectForTextContainer:textContainer].size.height;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    NSFont* font;
    NSTableColumn* column = [tableView tableColumnWithIdentifier:@"Message"];
    if( nil != column ){
        NSCell* cell = (NSCell*)[column dataCell];
        font = [NSFont fontWithName:@"Menlo" size:13];
        [cell setFont:font]; // FIXME: This should not be done here.
        float width = column.width;
        NSString* msg = ((XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)row]).message;
        if( nil == msg || [msg isEqualToString:@""] ){
            msg = @" ";
        }
        float ret = [self heightForString:msg withFont:font withWidth:width];
        return ret + 5;
    }
    return 13.0;
}

@end
