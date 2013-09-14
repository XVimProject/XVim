//
//  XVimTester+Visual.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/30/13.
//
//

#import "XVimTester.h"

@implementation XVimTester (Visual)
- (NSArray*)visual_testcases{
    static NSString* text1 = @"a;a bbb ccc\n";  // 0  4  8
    
    static NSString* text2 = @"a;a bbb ccc\n"  // 0  4  8
                             @"ddd e-e fff\n"  // 12 16 20
                             @"ggg hhh i_i\n"  // 24 28 32
                             @"    jjj kkk";   // 36 40 44
    
    static NSString* v_d_result = @"d e-e fff\n"
                                  @"ggg hhh i_i\n"
                                  @"    jjj kkk";
    
    static NSString* V_d_result = @"ggg hhh i_i\n"
                                  @"    jjj kkk";
    
    static NSString* rshift_result0 = @"        a;a bbb ccc\n" 
                                      @"        ddd e-e fff\n"
                                      @"ggg hhh i_i\n" 
                                      @"    jjj kkk"; 
    
    static NSString* rshift_result1 = @"    a;a bbb ccc\n"
                                      @"    ddd e-e fff\n"
                                      @"    ggg hhh i_i\n"
                                      @"        jjj kkk";
    
    static NSString* C_v_d_result = @" bbb ccc\n"
                                    @" e-e fff\n"
                                    @" hhh i_i\n"
                                    @"    jjj kkk";
    
    static NSString* vllccxxx_result= @"xxx bbb ccc\n";  // 0  4  8
    
    static NSString* vgU_result=  @"A;A BBB CCC\n"  // 0  4  8
                                  @"DDD e-e fff\n"  // 12 16 20
                                  @"ggg hhh i_i\n"  // 24 28 32
                                  @"    jjj kkk";   // 36 40 44
    
    static NSString* VgU_result=  @"A;A BBB CCC\n"  // 0  4  8
                                  @"DDD E-E FFF\n"  // 12 16 20
                                  @"ggg hhh i_i\n"  // 24 28 32
                                  @"    jjj kkk";   // 36 40 44
    
    static NSString* c_vgU_result=  @"A;A bbb ccc\n"  // 0  4  8
                                    @"DDD e-e fff\n"  // 12 16 20
                                    @"ggg hhh i_i\n"  // 24 28 32
                                    @"    jjj kkk";   // 36 40 44
    
    static NSString* J_result = @"a;a bbb ccc "
                                @"ddd e-e fff "
                                @"ggg hhh i_i "
                                @"jjj kkk"; 
    
    static NSString* p_result = @"a;a bbb ccc\n" 
                                @"a;a fff\n"
                                @"ggg hhh i_i\n" 
                                @"    jjj kkk";
    
    static NSString* Y_result = @"a;a bbb ccc\n"
                                @"a;a bbb ccc\n";
    
    static NSString* v_c_result = @"xxxbbb ccc\n";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text2, 0,  0, @"vljd", v_d_result, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"Vjd", V_d_result, 0, 0),
            
            // XVimMakeTestCase(text2, 0,  0, @"vjD", V_d_result, 0, 0), // not supported yet
            
            // Shift and repeat
            XVimMakeTestCase(text2, 0,  0, @"vj>."  , rshift_result0 , 0, 0), // #311
            XVimMakeTestCase(text2, 0,  0, @"vj>jj.", rshift_result1 ,32, 0),
            
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljjd", C_v_d_result, 0, 0),
            XVimMakeTestCase(text1, 0,  0, @"vllcxxx<ESC>", vllccxxx_result, 2, 0),
            XVimMakeTestCase(text2, 0,  0, @"vlljgU", vgU_result , 0, 0), // vgU
            XVimMakeTestCase(text2, 0,  0, @"vlljU",  vgU_result , 0, 0), // vU (same result with gU)
            XVimMakeTestCase(text2, 0,  0, @"VlljgU", VgU_result, 0, 0),  // VgU
            XVimMakeTestCase(text2, 0,  0, @"VlljU",  VgU_result, 0, 0),  // VU
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljgU", c_vgU_result, 0, 0), // <C-v>gU
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljU", c_vgU_result, 0, 0), // <C-v>U
            
            XVimMakeTestCase(text2, 0,  0, @"vlljgUvlljgu", text2, 0, 0), // make upper and reverse it to lower
            XVimMakeTestCase(text2, 0,  0, @"vlljgUvllju", text2, 0, 0), // make upper and reverse it to lower
            XVimMakeTestCase(text2, 0,  0, @"VlljgUVlljgu", text2, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"VlljgUVllju", text2, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljgU<C-v>lljgu", text2, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljgU<C-v>llju", text2, 0, 0),
            
            // Concanate
            XVimMakeTestCase(text2, 0,  0, @"VjjjJ", J_result, 35, 0), // The correct result location is not supported now
            
            
            // Yank , Put
            XVimMakeTestCase(text2, 0,  0, @"vllyjv6lp", p_result, 14, 0), // yank and paste with visual
            XVimMakeTestCase(text2, 0,  0, @"vllyjv6lP", p_result, 14, 0), // yank and paste with visual
            XVimMakeTestCase(text1, 0,  0, @"llvllYp", Y_result, 12, 0), // yank and paste with visual
            
            // Change
            XVimMakeTestCase(text1, 0,  0, @"vlllcxxx<ESC>", v_c_result, 2, 0), // change in visual
            
            // Toggle between v,C-v,V
            XVimMakeTestCase(text2, 0,  0, @"vllVjd", V_d_result, 0, 0), // change in visual
            XVimMakeTestCase(text2, 0,  0, @"Vjlvd", v_d_result, 0, 0), // change in visual
            XVimMakeTestCase(text2, 0,  0, @"vlljj<C-v>d", C_v_d_result, 0, 0), // change in visual
            
            // Text object in Visual mode
            XVimMakeTestCase(text2, 5,  0, @"viw", text2, 4, 3),
            XVimMakeTestCase(text2, 5,  0, @"vaw", text2, 4, 4),
            // Visual Line goes Visual Character with text object 
            XVimMakeTestCase(text2, 5,  0, @"Vjiw", text2, 5, 14), // Must extend one text object
            
            nil];
}
@end
