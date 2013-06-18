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
    
    return [NSArray arrayWithObjects:
            // map
            // unmap
            // mapclear
            XVimMakeTestCase(text2, 5,  0, @":map<SPACE>h<SPACE>l<CR>h", text2, 6, 0),
            XVimMakeTestCase(text2, 5,  0, @":unmap<SPACE>h<CR>h", text2, 4, 0),
            XVimMakeTestCase(text2, 5,  0, @":map<SPACE>jj<SPACE>l<CR>jj", text2, 6, 0),
            XVimMakeTestCase(text2, 5,  0, @":mapclear<CR>jj", text2, 29, 0),
            
            
            // noremap
            
            
            // imap
            // nmap
            // omap
            // vmap
            
    nil];
}

@end
