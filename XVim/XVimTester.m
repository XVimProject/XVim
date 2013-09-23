//
//  XVimTest.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import "XVimTester.h"
#import "Test/XVimTestCase.h"
#import <objc/runtime.h>
#import "Logger.h"
#import "IDEKit.h"
#import "XVimKeyStroke.h"
#import "XVimUtil.h"

/**
 * How to run test:
 *
 * 1 Write following line in .xvimrc (This makes Run Test menu command appeard)
 *     set debug
 *
 * 2 Set forcus on text source view
 *
 * 3 Select menu [XVim]-[Run Test] and follow the dialog.
 *
 **/
 
/**
 * How to create test cases:
 *
 * 1. Create category for XVimTester (unless you can find proper file to write test case)
 *    For example, create file with name "XVimTester+mytest.m" and write
 *       #import "XVimTester.h"
 *       @implementation XVimTester(mytest)
 *       @end
 *
 *    (You do not need to create .h for the category)
 *
 * 2. Define method named "*_testcases" where * is wildcard. The method must return NSArray*.
 *    For example 
 *       - (NSArra*)mytest_testcases{ ... }
 *
 * 3. Create array of test cases and return it. A test case must be created with XVimMakeTestCase Macro.
 *    For example
 *       return [NSArray arrayWithObjects:
 *                   XVimMakeTestCase("abc", 0, 0, "l", "abc", 1, 0),
 *                   XVimMakeTestCase("abc", 0, 0, "x",  "bc", 0, 0),
 *               nil];
 *     
 *    XVimMakeTestCase arguments are...
 *     Initial text,
 *     Initial selected range location,
 *     Initial selected range length,
 *     Vim command to test,
 *     Expected result text,
 *     Expected result selected range location,
 *     Expected result selected range length
 *
 *    The first example above means
 *     With the test "abc" and insertion point on "a" and input "l"
 *     must result in with the uncahnged text with the cursor at "b"
 *
 * 
 * Test cases you wrote automatically included and run.
 **/

@implementation XVimTester


- (id)init{
    return [self initWithTestCategory:nil];
}

- (id)initWithTestCategory:(NSString*)category{
    if( self = [super init] ){
    if( nil == category ){
        category = @"";
    }
        self.testCases = [[NSMutableArray alloc] init];
        unsigned int count = 0;
        Method* m = 0;
        m = class_copyMethodList([XVimTester class],  &count);
        for( unsigned int i = 0 ; i < count; i++ ){
            SEL sel = method_getName(m[i]);
            if( [NSStringFromSelector(sel) rangeOfString:[category stringByAppendingString:@"_testcases"]].location != NSNotFound ){
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
    [alert setMessageText:@"Running test deletes text in current source text view. Proceed?"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSInteger b = [alert runModal];
    
    if( b != NSAlertFirstButtonReturn ){
        return;
    }
    
    // Move forcus to source view
    [[XVimLastActiveWindowController() window] makeFirstResponder:XVimLastActiveSourceView()];
    // Run test for all the cases
    for( NSUInteger i = 0; i < testArray.count; i++ ){
        [(XVimTestCase*)[testArray objectAtIndex:i] run];
    }
    
    // Setup Talbe view to show result
    NSTableView* tableView= [[[NSTableView alloc] init] autorelease];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
   
    // Create Columns
    NSTableColumn* column1 = [[[NSTableColumn alloc] initWithIdentifier:@"Description" ] autorelease];
    [column1.headerCell setStringValue:@"Description"];
    NSTableColumn* column2 = [[[NSTableColumn alloc] initWithIdentifier:@"Pass/Fail" ] autorelease];
    [column2.headerCell setStringValue:@"Pass/Fail"];
    NSTableColumn* column3 = [[[NSTableColumn alloc] initWithIdentifier:@"Message" ] autorelease];
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
