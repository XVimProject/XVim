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
    
    return [NSArray arrayWithObjects:
            // map
            // unmap
            // mapclear
            XVimMakeTestCase(text2, 5,  0, @":map<SPACE>h<SPACE>l<CR>h", text2, 6, 0),
            XVimMakeTestCase(text2, 5,  0, @":unmap<SPACE>h<CR>h", text2, 4, 0),
            XVimMakeTestCase(text2, 5,  0, @":map<SPACE>jj<SPACE>l<CR>jj", text2, 6, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>jj", text2, 29, 0),
            
            // remapping
            // abc->def and defl->lll.  abc must resutls in lll
            XVimMakeTestCase(text2, 5,  0, @":map<SPACE>abc<SPACE>def<CR>:map<SPACE>def<SPACE>lll<CR>abc", text2, 8, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>", text2, 5, 0), // Just for reset the previous mapping
            
            // noremap
            // abc->lll (noremap) and lll->hhh.  abc must resutls in lll (not hhh)
            XVimMakeTestCase(text2, 5,  0, @":noremap<SPACE>abc<SPACE>lll<CR>:map<SPACE>lll<SPACE>hhh<CR>abc", text2, 8, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>", text2, 5, 0), // Just for reset the previous mapping
            
            
            // imap
            XVimMakeTestCase(text2, 4,  0, @":imap<SPACE>abc<SPACE>def<CR>xxxiabc<ESC>", imap_result1 , 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":iunmap<SPACE>abc<CR>xxxiabc<ESC>", imap_result2, 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":imap<SPACE>abc<SPACE>def<CR>:imapclear<CR>xxxiabc<ESC>", imap_result2 , 6, 0),
            XVimMakeTestCase(text2, 4,  0, @":imap<SPACE>lll<SPACE>hhh<CR>lll", text2, 7, 0), // imap does not affect NORMAL mode
            XVimMakeTestCase(text2, 4,  0, @":imapclear<CR>", text2, 4, 0),
            
            // nmap
            // omap
            // vmap
            
    nil];
}

@end
