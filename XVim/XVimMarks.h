//
//  XVimMarks.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/21/13.
//
//

#import <Foundation/Foundation.h>

@class XVimMark;

/**
 * This is a class for managing marks
 * In Vim they have 3 kinds of marks.
 *    - 'a-z' lowercase marks(local marks) which is valid within a file (each file has each lower case mark set)
 *    - 'A-Z' upper case marks(file marks) which is valid between file (One set of A-Z mars is shared by all files)
 *    - '0-9' numbered marks. This is special marks and XVim does not support it.
 *
 * And there is some special marks like ',`,.,^ ... (These are also managed witin local marks in this class)
 *
 * For local marks XVim create XVimMarks object for each document.
 * Marks are managed in NSDictionary like { @"a" => markObj, @"b" => markObj2, ... }
 * As a result this class has
 *    - one dictionary for file mark set (XVim global and shared by all the text views). Its like { @"A" => markObj, @"B"=> markObj2... }
 *    - multiple dictionaries for local mark set like
 *        { @"a" => markObj1, @"b" => markObj2, ... } for document1
 *        { @"a" => markObjX, @"b" => markObjY, ... } for document2
 *        ...
 * All the mark dictionaries have full set of marks. If a mark is not set its lineNumber properties is set to NSNotFound.
 *
 * Implementation Note:
 * You never replace mark object in a dictionary once you initialize the dictionary.
 * If you want to set change mark in a dictionary you must copy the data into the mark already in the dictionary.
 * This is because some marks shares one mark object in a dictionary (e.g. ` and ' marks)
 **/


/**
 * TODO:
 * We are not changing mark position when inserting newlines before the mark position.
 * Vim manages its text by keeping each lines and when it insert new line the mark position also moves accordingly
 **/


@interface XVimMarks : NSObject

/**
 * Returns mark.
 * This returns all sort of marks including local mark, file mark, or other special marks like ',<,[.
 * This automatically detects if it is file mark.
 * If the character is not supported as a mark this returns nil
 **/
- (XVimMark*)markForName:(NSString*)name forDocument:(NSString*)documentPath;

/**
 * Set mark.
 * This handles all sort of marks including local mark, file mark, or other special marks like ',<,[.
 * This automatically detects if it is file mark.
 * If the character is not supported it is just ignored.
 **/
- (void)setMark:(XVimMark*)mark forName:(NSString*)name;

/**
 * Returns list of XVimMarks object for a document.(Local Marks)
 * documentPath must be a full path since it identifies the XVimMarks object for the document by it.
 **/
- (NSDictionary*)marksForDocument:(NSString*)documentPath;

/**
 * Returns list of XVimMarks object for file marks.
 **/
@property(readonly) NSDictionary* fileMarks;

/**
 * Set file mark or local mark.
 *
 * Name must be one char beteen
 *     a-z for local marks
 *     A-Z for file marks
 * Otherwise they are just ignored
 **/
- (void)setLocalMark:(XVimMark*)mark forName:(NSString*)name;
- (void)setFileMark:(XVimMark*)mark forName:(NSString*)name;

/**
 * Dump marks as a string
 **/
- (NSString*)dumpMarksForDocument:(NSString*)document;
- (NSString*)dumpFileMarks;

@end
