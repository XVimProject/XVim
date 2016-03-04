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
    
    static NSString* text3 = @"    aaa\n"
                             @"    bbb\n";
    
    static NSString* text4 = @"aaa\n"   // 0  (index of each WORD)
                             @"bbb \n"  // 4  (space after b is intentional for J oepration test)
                             @"ccc\n"   // 8 
                             @"ddd\n"   // 12
                             @"eee\n"   // 16
                             @"fff";    // 20

    static NSString* C_v_o_result = @"a;a ccc\n"
                                    @"ddd fff\n"
                                    @"ggg i_i\n"
                                    @"    kkk";

    static NSString* Vyp_result = @"    aaa\n"
                                  @"    bbb\n"
                                  @"    aaa\n"
                                  @"    bbb\n";


    static NSString* VyP_result = @"    aaa\n"
                                  @"    aaa\n"
                                  @"    bbb\n"
                                  @"    bbb\n";
    
    static NSString* v_d_result = @"d e-e fff\n"
                                  @"ggg hhh i_i\n"
                                  @"    jjj kkk";
    
    static NSString* V_d_result = @"ggg hhh i_i\n"
                                  @"    jjj kkk";
    
    static NSString* rshift_result0 = @"        a;a bbb ccc\n" 
                                      @"        ddd e-e fff\n"
                                      @"ggg hhh i_i\n" 
                                      @"    jjj kkk"; 

    static NSString* rshift_result0_1 = @"\t\ta;a bbb ccc\n"
                                        @"\t\tddd e-e fff\n"
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
    
    static NSString* VGU_result=  @"a;a bbb ccc\n"  // 0  4  8
                                  @"DDD E-E FFF\n"  // 12 16 20
                                  @"GGG HHH I_I\n"  // 24 28 32
                                  @"    JJJ KKK";   // 36 40 44

    static NSString* vGU_result=  @"a;a bbb ccc\n"  // 0  4  8
                                  @"DDD E-E FFF\n"  // 12 16 20
                                  @"GGG HHH I_I\n"  // 24 28 32
                                  @"    Jjj kkk";   // 36 40 44
    
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
    
    static NSString* v_J_result0 = @"aaa bbb ccc\n"
                                   @"ddd\n"
                                   @"eee\n"
                                   @"fff";
    
    static NSString* v_J_result1 = @"aaa bbb ccc\n"
                                   @"ddd eee fff";
    
    static NSString* v_gJ_result0 = @"aaabbb ccc\n"
                                    @"ddd\n"
                                    @"eee\n"
                                    @"fff";
    
    static NSString* v_gJ_result1 = @"aaabbb ccc\n"
                                    @"dddeeefff";
    
    return [NSArray arrayWithObjects:
            XVimMakeTestCase(text2, 0,  0, @"vljd", v_d_result, 0, 0),
            XVimMakeTestCase(text2, 0,  0, @"Vjd", V_d_result, 0, 0),
            
            // XVimMakeTestCase(text2, 0,  0, @"vjD", V_d_result, 0, 0), // not supported yet
            
            // Shift and repeat
            XVimMakeTestCase(text2, 0,  0, @"vj>."  , rshift_result0 , 8, 0), // #311
            XVimMakeTestCase(text2, 0,  0, @"vj>..u", rshift_result0 , 8, 0),
            XVimMakeTestCase(text2, 0,  0, @"vj>jj.", rshift_result1 ,36, 0),
            XVimMakeTestCase(text2, 0,  0, @":set noexpandtab<CR>vj>.:set et<CR>", rshift_result0_1, 2, 0),
            
            XVimMakeTestCase(text2, 0,  0, @"<C-v>lljjd", C_v_d_result, 0, 0),
            XVimMakeTestCase(text1, 0,  0, @"vllcxxx<ESC>", vllccxxx_result, 2, 0),
            XVimMakeTestCase(text2, 0,  0, @"vlljgU", vgU_result , 0, 0), // vgU
            XVimMakeTestCase(text2, 14,  0, @"vggU",  vgU_result , 0, 0), // vggU (same result with gU)
            XVimMakeTestCase(text2, 12,  0, @"vGU",  vGU_result, 12, 0),  // vGU
            XVimMakeTestCase(text2, 0,  0, @"vlljU",  vgU_result , 0, 0), // vU (same result with gU)
            XVimMakeTestCase(text2, 12,  0, @"VggU", VgU_result, 0, 0),  // VggU
            XVimMakeTestCase(text2, 0,  0, @"VlljgU", VgU_result, 0, 0),  // VgU
            XVimMakeTestCase(text2, 0,  0, @"VlljU",  VgU_result, 0, 0),  // VU
            XVimMakeTestCase(text2, 12,  0, @"VGU",  VGU_result, 12, 0),  // VGU
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
            
            XVimMakeTestCase(text3, 0,  0, @"Vjyjp", Vyp_result, 16, 0), // yank and paste with visual line
            XVimMakeTestCase(text3, 0,  0, @"VjyjP", VyP_result, 8, 0), // yank and paste with visual line
            
            // Cusror position after put (Issue #506)
            XVimMakeTestCase(text1, 0, 0, @"vllypu", text1, 0, 0),  
            
            // Change
            XVimMakeTestCase(text1, 0,  0, @"vlllcxxx<ESC>", v_c_result, 2, 0), // change in visual

            // Toggle insertion point with o/O
            XVimMakeTestCase(@"abc\n", 1,  0, @"vlohd", @"\n", 0, 0),
            XVimMakeTestCase(@"abc\n", 1,  0, @"vlOhd", @"\n", 0, 0),

            XVimMakeTestCase(text2, 17,  0, @"<C-v>jjllokhd", C_v_o_result, 4, 0),
            XVimMakeTestCase(text2, 41,  0, @"<C-v>llkkOkhd", C_v_o_result, 4, 0),

            // Toggle between v,C-v,V
            XVimMakeTestCase(text2, 0,  0, @"vllVjd", V_d_result, 0, 0), // change in visual
            XVimMakeTestCase(text2, 0,  0, @"Vjlvd", v_d_result, 0, 0), // change in visual
            XVimMakeTestCase(text2, 0,  0, @"vlljj<C-v>d", C_v_d_result, 0, 0), // change in visual
            
            // Text object in Visual mode
            XVimMakeTestCase(text2, 4,  0, @"viw", text2, 4, 3),
            XVimMakeTestCase(text2, 5,  0, @"viw", text2, 4, 3),
            XVimMakeTestCase(text2, 6,  0, @"viw", text2, 4, 3),
            XVimMakeTestCase(text2, 4,  0, @"vaw", text2, 4, 4),
            XVimMakeTestCase(text2, 5,  0, @"vaw", text2, 4, 4),
            XVimMakeTestCase(text2, 6,  0, @"vaw", text2, 4, 4),
            // Visual Line goes Visual Character with text object 
            XVimMakeTestCase(text2, 5,  0, @"Vjiw", text2, 5, 14), // Must extend one text object
            XVimMakeTestCase(text2, 5,  0, @"Vjaw", text2, 5, 15), // Must extend one text object
            
            // J in visual
            XVimMakeTestCase(text4, 1, 0, @"<C-v>jjJ"   , v_J_result0, 8, 0), // join 2 lines
            // XVimMakeTestCase(text4, 1, 0, @"<C-v>jjJj." , v_J_result1,19, 0), // Repeat (not supported yet)
            XVimMakeTestCase(text4, 1, 0, @"<C-v>jjJ`." , v_J_result0,12, 0), // . Mark
            
            // gJ in visual
            XVimMakeTestCase(text4, 1, 0, @"<C-v>jjgJ"   , v_gJ_result0, 7, 0), // join 2 lines
            // XVimMakeTestCase(text4, 1, 0, @"<C-v>jjgJj." , v_gJ_result1,17, 0), // Repeat (not supported yet)
            XVimMakeTestCase(text4, 1, 0, @"<C-v>jjgJ`." , v_gJ_result0,11, 0), // . Mark

            // ge, gE in visual
            XVimMakeTestCase(text2, 18, 0, @"vge", text2, 17, 2),
            XVimMakeTestCase(text2, 18, 0, @"vgE", text2, 14, 5),
            XVimMakeTestCase(text2, 18, 0, @"v2ge", text2, 16, 3),
            XVimMakeTestCase(text2, 18, 0, @"v2gE", text2, 10, 9),
            
            nil];
}
@end
