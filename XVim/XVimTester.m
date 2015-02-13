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


@interface XVimTester(){
    NSWindow* results;
    NSTableView* tableView;
    NSTextField* resultsString;
    BOOL showPassing;
    NSNumber* totalTests;
    NSNumber* passingTests;
}
@property (strong) NSMutableArray* testCases;
@end


@implementation XVimTester

- (id)init{
    if( self = [super init] ){
        self.testCases = [NSMutableArray array];
        showPassing = false;
    }
    return self;
}


- (NSArray*)categories{
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    unsigned int count = 0;
    Method* m = 0;
    m = class_copyMethodList([XVimTester class],  &count);
    for( unsigned int i = 0 ; i < count; i++ ){
        SEL sel = method_getName(m[i]);
        if( [NSStringFromSelector(sel) hasSuffix:@"_testcases"] ){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [arr addObject:[[NSStringFromSelector(sel) componentsSeparatedByString:@"_"] objectAtIndex:0]];
#pragma clang diagnostic pop
        }
    }
    return arr;
}

- (void)selectCategories:(NSArray*)categories{
    [self.testCases removeAllObjects];
    for( NSString* c in categories){
        SEL sel = NSSelectorFromString([c stringByAppendingString:@"_testcases"]);
        if( [self respondsToSelector:sel]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSArray* ary = [self performSelector:sel];
#pragma clang diagnostic pop
            [self.testCases addObjectsFromArray:ary];
        }
    }
}

- (void)runTest{
    // Create Test Cases
    NSArray* testArray = self.testCases;
    
    NSFileManager* fm = [[NSFileManager alloc] init];
    NSString* filename = @"/tmp/xvimtest.cpp"; // The tmp file extension must be .cpp , .m or other source file extension.
                                               // This is because some test case depend on source code format feature.
                                               // If it is .txt or .tmp source code format is not invoked and some test cases fails.
    BOOL isDirectory;
    if( ![fm fileExistsAtPath:filename isDirectory:&isDirectory] ){
        [fm createFileAtPath:filename contents:nil attributes:nil];
    }
    
    IDEDocumentController* ctrl = [IDEDocumentController sharedDocumentController];
    NSError* error;
    NSURL* doc = [NSURL fileURLWithPath:filename];
    [ctrl openDocumentWithContentsOfURL:doc display:YES error:&error];
    
	// Close NSWindow to make test run properly
	[results close];
	results = nil;
    
dispatch_async(dispatch_get_main_queue(), ^{
    
    // Move forcus to source view
    [[XVimLastActiveWindowController() window] makeFirstResponder:XVimLastActiveSourceView()];
    // Run test for all the cases
    for( NSUInteger i = 0; i < testArray.count; i++ ){
        [(XVimTestCase*)[testArray objectAtIndex:i] run];
    }
    
    // Setup Talbe view to show result
    tableView = [[NSTableView alloc] init];
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
    
    //setup a window to show the tableview, scrollview, and results toggling button.
    NSUInteger mask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
    results = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 700, 500) styleMask:mask backing:NSBackingStoreBuffered defer:false];
	// Prevent from crashing on ARC
	[results setReleasedWhenClosed:NO];
    
    // Setup the table view into scroll view
    NSScrollView* scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 40, 700, 445)];
    [scroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [scroll setDocumentView:tableView];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:YES];
    
    //setup the results toggle button
    NSButton* toggleResultsButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)];
    [toggleResultsButton setTitle:@"Toggle Results"];
    [toggleResultsButton setBezelStyle:NSRoundedBezelStyle];
    [toggleResultsButton setTarget:self];
    [toggleResultsButton setAction:@selector(toggleResults:)];
    
    
    resultsString = [[NSTextField alloc] initWithFrame:NSMakeRect(550, 0, 200, 40)];
    [resultsString setStringValue:@"0 out of 0 test passing"];
    [resultsString setAutoresizingMask:NSViewMinXMargin | NSViewMaxYMargin];
    [resultsString setBezeled:NO];
    [resultsString setDrawsBackground:NO];
    [resultsString setEditable:NO];
    [resultsString setSelectable:NO];
    
    //setup the main content view for the window and add the controls to it.
    NSView * resultsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 700, 450)];
    
    [results setContentView:resultsView];
    
    [resultsView addSubview:scroll];
    [resultsView addSubview:resultsString];
    [resultsView addSubview:toggleResultsButton];
    [resultsView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    [self updateResultsString];
    
    [results makeKeyAndOrderFront:results];
});
    
}

-(void) updateResultsString{
    NSInteger totalCases = 0;
    NSInteger passingCases = 0;
    NSInteger failingCases = 0;
    
    for(XVimTestCase* tc in self.testCases){
        if(!tc.success){
            failingCases++;
        }
        else{
            passingCases++;
        }
        totalCases++;
    }
    
    [resultsString setStringValue: [NSString stringWithFormat:@"%lu Passing Tests\n%lu Failing Tests", passingCases, failingCases]];
}

-(IBAction) toggleResults: (id) sender {
    showPassing = !showPassing;
    [tableView reloadData];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    if(showPassing){
       return (NSInteger)[self.testCases count];
    }else
    {
        NSInteger runningCount = 0;
        for(XVimTestCase* tc in self.testCases){
            if(!tc.success){
                runningCount++;
            }
        }
        return runningCount;
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    
    XVimTestCase* resultRow;
    
    if(showPassing){
        resultRow = (XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)rowIndex];
    }else{
       NSInteger index = [self getIndexOfNthFailingTestcase:rowIndex];
       resultRow = (XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)index];
    }
    
    if( [aTableColumn.identifier isEqualToString:@"Description"] ){
        return [resultRow desc];
    }else if( [aTableColumn.identifier isEqualToString:@"Pass/Fail"] ){
        return (resultRow.success) ? @"Pass" : @"Fail";
    }else if( [aTableColumn.identifier isEqualToString:@"Message"] ){
        return resultRow.message;
    }
    return nil;
}

-(NSInteger) getIndexOfNthFailingTestcase:(NSInteger)nth{
    NSInteger runningCount = -1;
    NSInteger retval = -1;
    for(XVimTestCase* tc in self.testCases){
        retval++;
        if(!tc.success){
            runningCount++;
            if (runningCount == nth) {
                break;
            }
        }
    }
    return  retval;
}

- (float)heightForString:(NSString*)myString withFont:(NSFont*)myFont withWidth:(float)myWidth{
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:myString];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(myWidth, FLT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textStorage addAttribute:NSFontAttributeName value:myFont
                        range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager
            usedRectForTextContainer:textContainer].size.height;
}

- (CGFloat)tableView:(NSTableView *)tv heightOfRow:(NSInteger)row{
    NSFont* font;
    NSTableColumn* column = [tv tableColumnWithIdentifier:@"Message"];
    if( nil != column ){
        NSCell* cell = (NSCell*)[column dataCell];
        font = [NSFont fontWithName:@"Menlo" size:13];
        [cell setFont:font]; // FIXME: This should not be done here.
        float width = column.width;
        NSString* msg;
        if(showPassing){
            msg = ((XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)row]).message;
        }else{
            NSInteger index = [self getIndexOfNthFailingTestcase:row];
			if( index >= 0 ){
                msg = ((XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)index]).message;
			}
        }
        if( nil == msg || [msg isEqualToString:@""] ){
            msg = @" ";
        }
        float ret = [self heightForString:msg withFont:font withWidth:width];
        return ret + 10;
    }
    return 13.0;
}

@end
