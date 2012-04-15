//
//  XVimExCommand.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>

// This file corresponds Vim's ex_cmds.h
// Wondering if we can reuse ex_*.* files in Vim...

// Here's the struct Vim using to express ex command.
// XVimExArg is based on this struct but has more Objective-C like members and does not have unsupported members by XVim at the moment.
//struct exarg
//{
//    char_u	*arg;		/* argument of the command */
//    char_u	*nextcmd;	/* next command (NULL if none) */
//    char_u	*cmd;		/* the name of the command (except for :make) */
//    char_u	**cmdlinep;	/* pointer to pointer of allocated cmdline */
//    cmdidx_T	cmdidx;		/* the index for the command */
//    long	argt;		/* flags for the command */
//    int		skip;		/* don't execute the command, only parse it */
//    int		forceit;	/* TRUE if ! present */
//    int		addr_count;	/* the number of addresses given */
//    linenr_T	line1;		/* the first line number */
//    linenr_T	line2;		/* the second line number or count */
//    int		flags;		/* extra flags after count: EXFLAG_ */
//    char_u	*do_ecmd_cmd;	/* +command arg to be used in edited file */
//    linenr_T	do_ecmd_lnum;	/* the line number in an edited file */
//    int		append;		/* TRUE with ":w >>file" command */
//    int		usefilter;	/* TRUE with ":w !command" and ":r!command" */
//    int		amount;		/* number of '>' or '<' for shift command */
//    int		regname;	/* register name (NUL if none) */
//    int		force_bin;	/* 0, FORCE_BIN or FORCE_NOBIN */
//    int		read_edit;	/* ++edit argument */
//    int		force_ff;	/* ++ff= argument (index in cmd[]) */
//#ifdef FEAT_MBYTE
//    int		force_enc;	/* ++enc= argument (index in cmd[]) */
//    int		bad_char;	/* BAD_KEEP, BAD_DROP or replacement byte */
//#endif
//#ifdef FEAT_USR_CMDS
//    int		useridx;	/* user command index */
//#endif
//    char_u	*errmsg;	/* returned error message */
//    char_u	*(*getline) __ARGS((int, void *, int));
//    void	*cookie;	/* argument for getline() */
//#ifdef FEAT_EVAL
//    struct condstack *cstack;	/* condition stack for ":if" etc. */
//#endif
//};

@class XVimWindow;

@interface XVimExArg : NSObject{
}
@property (retain) NSString* arg;
@property (retain) NSString* cmd;
@property BOOL forceit;
@property NSUInteger lineBegin; // line1
@property NSUInteger lineEnd; // line2
@property NSUInteger addr_count;
@end

// XVimExCmd corresponds cmdname struct in ex_cmds.h
@interface XVimExCmdname : NSObject{

}
@property (readonly) NSString* cmdName;
@property (readonly) NSString* methodName;
@end


@interface XVimExCommand : NSObject{
    NSArray* _excommands;
}
- (void)executeCommand:(NSString*)cmd inWindow:(XVimWindow*)window;
@end
