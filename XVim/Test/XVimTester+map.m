//
//  XVimTester+map.m
//  XVim
//
//  Created by Suzuki Shuichiro on 6/19/13.
//
//

#import "XVimtester.h"

@implementation XVimTester (map)
- (NSArray*)map_testcases{
    static NSString* text2 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    static NSString* imap_result1 = @"a;a def ccc\n"  // 0  4  8
                                    @"ddd e-e fff\n"  // 12 16 20
                                    @"ggg hhh i_i\n"  // 24 28 32
                                    @"    jjj kkk";   // 36 40 44
    
    static NSString* imap_result2 = @"a;a abc ccc\n"  // 0  4  8
                                    @"ddd e-e fff\n"  // 12 16 20
                                    @"ggg hhh i_i\n"  // 24 28 32
                                    @"    jjj kkk";   // 36 40 44
    
    static NSString* nmap_result1 = @"a;a ccc\n"
                                    @"ddd e-e fff\n"
                                    @"ggg hhh i_i\n"
                                    @"    jjj kkk";
    
    static NSString* nmap_result2 = @"a;a bbcbb ccc\n"
                                    @"ddd e-e fff\n"
                                    @"ggg hhh i_i\n"
                                    @"    jjj kkk";
    
    static NSString* nmap_result3 = @"a;a bbcbb ccc\n"
                                    @"ddd e-e fff\n"
                                    @"ggg hhh i_i\n"
                                    @"    jjj kkk";
    
    static NSString* nmap_result4 = @"a;a abcbbb ccc\n"
                                    @"ddd e-e fff\n"
                                    @"ggg hhh i_i\n"
                                    @"    jjj kkk";
    
    
    return [NSArray arrayWithObjects:
            // map
            // unmap
            // mapclear
            XVimMakeTestCase(text2, 5,  0, @":map h l<CR>h",   text2,  6, 0),
            XVimMakeTestCase(text2, 5,  0, @":unmap h<CR>h",   text2,  4, 0),
            XVimMakeTestCase(text2, 5,  0, @":map jj l<CR>jj", text2,  6, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>jj", text2, 29, 0),
            
            // remapping
            // abc->def and def->lll.  abc must resutls in lll
            XVimMakeTestCase(text2, 5,  0, @":map abc def<CR>:map def lll<CR>abc", text2, 8, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>",                       text2, 5, 0), // Just for reset the previous mapping
            
            // noremap
            // abc->lll (noremap) and lll->hhh.  abc must resutls in lll (not hhh)
            XVimMakeTestCase(text2, 5,  0, @":noremap abc lll<CR>:map lll hhh<CR>abc", text2, 8, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>",                           text2, 5, 0), // Just for reset the previous mapping
            
            // imap
            XVimMakeTestCase(text2, 4,  0, @":imap abc def<CR>xxxiabc<ESC>",               imap_result1, 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":iunmap abc<CR>xxxiabc<ESC>",                 imap_result2, 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":imap abc def<CR>:imapclear<CR>xxxiabc<ESC>", imap_result2, 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":imap lll hhh<CR>lll",                        text2       , 7, 0), // imap does not affect NORMAL mode
            XVimMakeTestCase(text2, 4,  0, @":imapclear<CR>",                              text2       , 4, 0), // Reset mapping
            
            // nmap
            XVimMakeTestCase(text2, 4,  0, @":nmap abc dw<CR>abc",                    nmap_result1, 4, 0),
            XVimMakeTestCase(text2, 4,  0, @":nunmap abc<CR>abc<ESC>",                nmap_result2, 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":nmap abc dw<CR>:nmapclear<CR>abc<ESC>", nmap_result3, 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":nmap abc dw<CR>iabc<ESC>",              nmap_result4, 6, 0), // nmap does not affect insert mode
            XVimMakeTestCase(text2, 4,  0, @":nmapclear<CR>",                         text2,        4, 0),
            
            // omap
            // vmap
            
    nil];
}

@end
