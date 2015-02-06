//
//  XVimExCommand.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerSHu.Net. All rights reserved.
//

#import "XVimExCommand.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "IDEWorkspaceTabController+XVim.h"
#import "NSTextView+VimOperation.h"
#import "NSString+VimHelper.h"
#import "Logger.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimOptions.h"
#import "XVimTester.h"
#import "IDEKit.h"
#import "XVimDebug.h"
#import "XVimRegister.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimUtil.h"
#import "XVimTester.h"

@implementation XVimExArg
@synthesize arg,cmd,forceit,noRangeSpecified,lineBegin,lineEnd,addr_count;
@end

// Maximum time in seconds for a 'bang' command to run before being killed as taking too long
static const NSTimeInterval EXTERNAL_COMMAND_TIMEOUT_SECS = 5.0;

@implementation XVimExCmdname
@synthesize cmdName,methodName;

-(id)initWithCmd:(NSString*)cmd method:(NSString*)method{
    if( self = [super init] ){
        cmdName = cmd;
        methodName = method;
    }
    return self;
}
@end


@implementation XVimExCommand
#define CMD(cmd,mtd) [[XVimExCmdname alloc] initWithCmd:cmd method:mtd]
-(id)init {
    if( self = [super init] ){
        // This is the ex command list.
        // This is list from ex_cmds.h in Vim source code.
        // The method names correspond the Vim's function name.
        // You can change the method name as needed ( Since Vim's one is not always suitable )
        
        _excommands = [[NSArray alloc] initWithObjects:
                       CMD(@"append", @"append:inWindow:"),
                       CMD(@"abbreviate", @"abbreviate:inWindow:"),
                       CMD(@"abclear", @"abclear:inWindow:"),
                       CMD(@"aboveleft", @"wrongmodifier:inWindow:"),
                       CMD(@"all", @"all:inWindow:"),
                       CMD(@"amenu", @"menu:inWindow:"),
                       CMD(@"anoremenu", @"menu:inWindow:"),
                       CMD(@"args", @"args:inWindow:"),
                       CMD(@"argadd", @"argadd:inWindow:"),
                       CMD(@"argdelete", @"argdelete:inWindow:"),
                       CMD(@"argdo", @"listdo:inWindow:"),
                       CMD(@"argedit", @"argedit:inWindow:"),
                       CMD(@"argglobal", @"args:inWindow:"),
                       CMD(@"arglocal", @"args:inWindow:"),
                       CMD(@"argument", @"argument:inWindow:"),
                       CMD(@"ascii", @"ascii:inWindow:"),
                       CMD(@"autocmd", @"autocmd:inWindow:"),
                       CMD(@"augroup", @"autocmd:inWindow:"),
                       CMD(@"aunmenu", @"menu:inWindow:"),
                       CMD(@"buffer", @"buffer:inWindow:"),
                       CMD(@"bNext", @"bprevious:inWindow:"),
                       CMD(@"ball", @"buffer_all:inWindow:"),
                       CMD(@"badd", @"edit:inWindow:"),
                       CMD(@"bdelete", @"bunload:inWindow:"),
                       CMD(@"behave", @"behave:inWindow:"),
                       CMD(@"belowright", @"wrongmodifier:inWindow:"),
                       CMD(@"bfirst", @"brewind:inWindow:"),
                       CMD(@"blast", @"blast:inWindow:"),
                       CMD(@"bmodified", @"bmodified:inWindow:"),
                       CMD(@"bnext", @"bnext:inWindow:"),
                       CMD(@"botright", @"wrongmodifier:inWindow:"),
                       CMD(@"bprevious", @"bprevious:inWindow:"),
                       CMD(@"brewind", @"brewind:inWindow:"),
                       CMD(@"break", @"break:inWindow:"),
                       CMD(@"breakadd", @"breakadd:inWindow:"),
                       CMD(@"breakdel", @"breakdel:inWindow:"),
                       CMD(@"breaklist", @"breaklist:inWindow:"),
                       CMD(@"browse", @"wrongmodifier:inWindow:"),
                       CMD(@"buffers", @"buflist_list:inWindow:"),
                       CMD(@"bufdo", @"listdo:inWindow:"),
                       CMD(@"bunload", @"bunload:inWindow:"),
                       CMD(@"bwipeout", @"bunload:inWindow:"),
                       CMD(@"change", @"change:inWindow:"),
                       CMD(@"cNext", @"cnext:inWindow:"),
                       CMD(@"cNfile", @"cnext:inWindow:"),
                       CMD(@"cabbrev", @"abbreviate:inWindow:"),
                       CMD(@"cabclear", @"abclear:inWindow:"),
                       CMD(@"caddbuffer", @"cbuffer:inWindow:"),
                       CMD(@"caddexpr", @"cexpr:inWindow:"),
                       CMD(@"caddfile", @"cfile:inWindow:"),
                       CMD(@"call", @"call:inWindow:"),
                       CMD(@"catch", @"catch:inWindow:"),
                       CMD(@"cbuffer", @"cbuffer:inWindow:"),
                       CMD(@"cc", @"cc:inWindow:"),
                       CMD(@"cclose", @"cclose:inWindow:"),
                       CMD(@"cd", @"cd:inWindow:"),
                       CMD(@"center", @"align:inWindow:"),
                       CMD(@"cexpr", @"cexpr:inWindow:"),
                       CMD(@"cfile", @"cfile:inWindow:"),
                       CMD(@"cfirst", @"cc:inWindow:"),
                       CMD(@"cgetfile", @"cfile:inWindow:"),
                       CMD(@"cgetbuffer", @"cbuffer:inWindow:"),
                       CMD(@"cgetexpr", @"cexpr:inWindow:"),
                       CMD(@"chdir", @"cd:inWindow:"),
                       CMD(@"changes", @"changes:inWindow:"),
                       CMD(@"checkpath", @"checkpath:inWindow:"),
                       CMD(@"checktime", @"checktime:inWindow:"),
                       CMD(@"clist", @"qf_list:inWindow:"),
                       CMD(@"clast", @"cc:inWindow:"),
                       CMD(@"close", @"close:inWindow:"),
                       CMD(@"cmap", @"cmap:inWindow:"),
                       CMD(@"cmapclear", @"cmapclear:inWindow:"),
                       CMD(@"cmenu", @"menu:inWindow:"),
                       CMD(@"cnext", @"cnext:inWindow:"),
                       CMD(@"cnewer", @"qf_age:inWindow:"),
                       CMD(@"cnfile", @"cnext:inWindow:"),
                       CMD(@"cnoremap", @"cnoremap:inWindow:"),
                       CMD(@"cnoreabbrev", @"abbreviate:inWindow:"),
                       CMD(@"cnoremenu", @"menu:inWindow:"),
                       CMD(@"copy", @"copymove:inWindow:"),
                       CMD(@"colder", @"qf_age:inWindow:"),
                       CMD(@"colorscheme", @"colorscheme:inWindow:"),
                       CMD(@"command", @"command:inWindow:"),
                       CMD(@"commit", @"commit:inWindow:"),    // Source control commit (XVim Original)
                       CMD(@"comclear", @"comclear:inWindow:"),
                       CMD(@"compiler", @"compiler:inWindow:"),
                       CMD(@"continue", @"continue:inWindow:"),
                       CMD(@"confirm", @"wrongmodifier:inWindow:"),
                       CMD(@"copen", @"copen:inWindow:"),
                       CMD(@"cprevious", @"cnext:inWindow:"),
                       CMD(@"cpfile", @"cnext:inWindow:"),
                       CMD(@"cquit", @"cquit:inWindow:"),
                       CMD(@"crewind", @"cc:inWindow:"),
                       CMD(@"cscope", @"cscope:inWindow:"),
                       CMD(@"cstag", @"cstag:inWindow:"),
                       CMD(@"cunmap", @"cunmap:inWindow:"),
                       CMD(@"cunabbrev", @"abbreviate:inWindow:"),
                       CMD(@"cunmenu", @"menu:inWindow:"),
                       CMD(@"cwindow", @"cwindow:inWindow:"),
                       CMD(@"delete", @"operators:inWindow:"),
                       CMD(@"delmarks", @"delmarks:inWindow:"),
                       CMD(@"debug", @"debug:inWindow:"),  // This currently works as XVim debug command
                       CMD(@"debuggreedy", @"debuggreedy:inWindow:"),
                       CMD(@"delcommand", @"delcommand:inWindow:"),
                       CMD(@"delfunction", @"delfunction:inWindow:"),
                       CMD(@"display", @"display:inWindow:"),
                       CMD(@"diffupdate", @"diffupdate:inWindow:"),
                       CMD(@"diffget", @"diffgetput:inWindow:"),
                       CMD(@"diffoff", @"diffoff:inWindow:"),
                       CMD(@"diffpatch", @"diffpatch:inWindow:"),
                       CMD(@"diffput", @"diffgetput:inWindow:"),
                       CMD(@"diffsplit", @"diffsplit:inWindow:"),
                       CMD(@"diffthis", @"diffthis:inWindow:"),
                       CMD(@"digraphs", @"digraphs:inWindow:"),
                       CMD(@"djump", @"findpat:inWindow:"),
                       CMD(@"dlist", @"findpat:inWindow:"),
                       CMD(@"doautocmd", @"doautocmd:inWindow:"),
                       CMD(@"doautoall", @"doautoall:inWindow:"),
                       CMD(@"drop", @"drop:inWindow:"),
                       CMD(@"dsearch", @"findpat:inWindow:"),
                       CMD(@"dsplit", @"findpat:inWindow:"),
                       CMD(@"edit", @"edit:inWindow:"),
                       CMD(@"earlier", @"later:inWindow:"),
                       CMD(@"echo", @"echo:inWindow:"),
                       CMD(@"echoerr", @"execute:inWindow:"),
                       CMD(@"echohl", @"echohl:inWindow:"),
                       CMD(@"echomsg", @"execute:inWindow:"),
                       CMD(@"echon", @"echo:inWindow:"),
                       CMD(@"else", @"else:inWindow:"),
                       CMD(@"elseif", @"else:inWindow:"),
                       CMD(@"emenu", @"emenu:inWindow:"),
                       CMD(@"endif", @"endif:inWindow:"),
                       CMD(@"endfunction", @"endfunction:inWindow:"),
                       CMD(@"endfor", @"endwhile:inWindow:"),
                       CMD(@"endtry", @"endtry:inWindow:"),
                       CMD(@"endwhile", @"endwhile:inWindow:"),
                       CMD(@"enew", @"edit:inWindow:"),
                       CMD(@"ex", @"edit:inWindow:"),
                       CMD(@"execute", @"execute:inWindow:"),
                       CMD(@"exit", @"exit:inWindow:"),
                       CMD(@"exusage", @"exusage:inWindow:"),
                       CMD(@"file", @"file:inWindow:"),
                       CMD(@"files", @"buflist_list:inWindow:"),
                       CMD(@"filetype", @"filetype:inWindow:"),
                       CMD(@"find", @"find:inWindow:"),
                       CMD(@"finally", @"finally:inWindow:"),
                       CMD(@"finish", @"finish:inWindow:"),
                       CMD(@"first", @"rewind:inWindow:"),
                       CMD(@"fixdel", @"fixdel:inWindow:"),
                       CMD(@"fold", @"fold:inWindow:"),
                       CMD(@"foldclose", @"foldopen:inWindow:"),
                       CMD(@"folddoopen", @"folddo:inWindow:"),
                       CMD(@"folddoclosed", @"folddo:inWindow:"),
                       CMD(@"foldopen", @"foldopen:inWindow:"),
                       CMD(@"for", @"while:inWindow:"),
                       CMD(@"function", @"function:inWindow:"),
                       CMD(@"global", @"global:inWindow:"),
                       CMD(@"goto", @"goto:inWindow:"),
                       CMD(@"grep", @"make:inWindow:"),
                       CMD(@"grepadd", @"make:inWindow:"),
                       CMD(@"gui", @"gui:inWindow:"),
                       CMD(@"gvim", @"gui:inWindow:"),
                       CMD(@"help", @"help:inWindow:"),
                       CMD(@"helpfind", @"helpfind:inWindow:"),
                       CMD(@"helpgrep", @"helpgrep:inWindow:"),
                       CMD(@"helptags", @"helptags:inWindow:"),
                       CMD(@"hardcopy", @"hardcopy:inWindow:"),
                       CMD(@"highlight", @"highlight:inWindow:"),
                       CMD(@"hide", @"hide:inWindow:"),
                       CMD(@"history", @"history:inWindow:"),
                       CMD(@"insert", @"append:inWindow:"),
                       CMD(@"iabbrev", @"abbreviate:inWindow:"),
                       CMD(@"iabclear", @"abclear:inWindow:"),
                       CMD(@"if", @"if:inWindow:"),
                       CMD(@"ijump", @"findpat:inWindow:"),
                       CMD(@"ilist", @"findpat:inWindow:"),
                       CMD(@"imap", @"imap:inWindow:"),
                       CMD(@"imapclear", @"imapclear:inWindow:"),
                       CMD(@"imenu", @"menu:inWindow:"),
                       CMD(@"inoremap", @"inoremap:inWindow:"),
                       CMD(@"inoreabbrev", @"abbreviate:inWindow:"),
                       CMD(@"inoremenu", @"menu:inWindow:"),
                       CMD(@"intro", @"intro:inWindow:"),
                       CMD(@"isearch", @"findpat:inWindow:"),
                       CMD(@"isplit", @"findpat:inWindow:"),
                       CMD(@"iunmap", @"iunmap:inWindow:"),
                       CMD(@"iunabbrev", @"abbreviate:inWindow:"),
                       CMD(@"iunmenu", @"menu:inWindow:"),
                       CMD(@"join", @"join:inWindow:"),
                       CMD(@"jumps", @"jumps:inWindow:"),
                       CMD(@"k", @"mark:inWindow:"),
                       CMD(@"keepmarks", @"wrongmodifier:inWindow:"),
                       CMD(@"keepjumps", @"wrongmodifier:inWindow:"),
                       CMD(@"keepalt", @"wrongmodifier:inWindow:"),
                       CMD(@"list", @"print:inWindow:"),
                       CMD(@"lNext", @"cnext:inWindow:"),
                       CMD(@"lNfile", @"cnext:inWindow:"),
                       CMD(@"last", @"last:inWindow:"),
                       CMD(@"language", @"language:inWindow:"),
                       CMD(@"laddexpr", @"cexpr:inWindow:"),
                       CMD(@"laddbuffer", @"cbuffer:inWindow:"),
                       CMD(@"laddfile", @"cfile:inWindow:"),
                       CMD(@"later", @"later:inWindow:"),
                       CMD(@"lbuffer", @"cbuffer:inWindow:"),
                       CMD(@"lcd", @"cd:inWindow:"),
                       CMD(@"lchdir", @"cd:inWindow:"),
                       CMD(@"lclose", @"cclose:inWindow:"),
                       CMD(@"lcscope", @"cscope:inWindow:"),
                       CMD(@"left", @"align:inWindow:"),
                       CMD(@"leftabove", @"wrongmodifier:inWindow:"),
                       CMD(@"let", @"let:inWindow:"),
                       CMD(@"lexpr", @"cexpr:inWindow:"),
                       CMD(@"lfile", @"cfile:inWindow:"),
                       CMD(@"lfirst", @"cc:inWindow:"),
                       CMD(@"lgetfile", @"cfile:inWindow:"),
                       CMD(@"lgetbuffer", @"cbuffer:inWindow:"),
                       CMD(@"lgetexpr", @"cexpr:inWindow:"),
                       CMD(@"lgrep", @"make:inWindow:"),
                       CMD(@"lgrepadd", @"make:inWindow:"),
                       CMD(@"lhelpgrep", @"helpgrep:inWindow:"),
                       CMD(@"ll", @"cc:inWindow:"),
                       CMD(@"llast", @"cc:inWindow:"),
                       CMD(@"llist", @"qf_list:inWindow:"),
                       CMD(@"lmap", @"map:inWindow:"),
                       CMD(@"lmapclear", @"mapclear:inWindow:"),
                       CMD(@"lmake", @"make:inWindow:"),
                       CMD(@"lnoremap", @"map:inWindow:"),
                       CMD(@"lnext", @"cnext:inWindow:"),
                       CMD(@"lnewer", @"qf_age:inWindow:"),
                       CMD(@"lnfile", @"cnext:inWindow:"),
                       CMD(@"loadview", @"loadview:inWindow:"),
                       CMD(@"loadkeymap", @"loadkeymap:inWindow:"),
                       CMD(@"lockmarks", @"wrongmodifier:inWindow:"),
                       CMD(@"lockvar", @"lockvar:inWindow:"),
                       CMD(@"lolder", @"qf_age:inWindow:"),
                       CMD(@"lopen", @"copen:inWindow:"),
                       CMD(@"lprevious", @"cnext:inWindow:"),
                       CMD(@"lpfile", @"cnext:inWindow:"),
                       CMD(@"lrewind", @"cc:inWindow:"),
                       CMD(@"ltag", @"tag:inWindow:"),
                       CMD(@"lunmap", @"unmap:inWindow:"),
                       CMD(@"lvimgrep", @"vimgrep:inWindow:"),
                       CMD(@"lvimgrepadd", @"vimgrep:inWindow:"),
                       CMD(@"lwindow", @"cwindow:inWindow:"),
                       CMD(@"ls", @"	buflist_list:inWindow:"),
                       CMD(@"move", @"copymove:inWindow:"),
                       CMD(@"mark", @"mark:inWindow:"),
                       CMD(@"make", @"make:inWindow:"),
                       CMD(@"map", @"map:inWindow:"),
                       CMD(@"mapclear", @"mapclear:inWindow:"),
                       CMD(@"marks", @"marks:inWindow:"),
                       CMD(@"match", @"match:inWindow:"),
                       CMD(@"menu", @"menu:inWindow:"),
                       CMD(@"menutranslate", @"menutranslate:inWindow:"),
                       CMD(@"messages", @"messages:inWindow:"),
                       CMD(@"mkexrc", @"mkrc:inWindow:"),
                       CMD(@"mksession", @"mkrc:inWindow:"),
                       CMD(@"mkspell", @"mkspell:inWindow:"),
                       CMD(@"mkvimrc", @"mkrc:inWindow:"),
                       CMD(@"mkview", @"mkrc:inWindow:"),
                       CMD(@"mode", @"mode:inWindow:"),
                       CMD(@"mzscheme", @"mzscheme:inWindow:"),
                       CMD(@"mzfile", @"mzfile:inWindow:"),
                       CMD(@"next", @"next:inWindow:"),
                       CMD(@"nbkey", @"nbkey:inWindow:"),
                       CMD(@"ncounterpart", @"ncounterpart:inWindow:"),    // XVim Original
                       CMD(@"new", @"splitview:inWindow:"),
                       CMD(@"nissue", @"nissue:inWindow:"),    // XVim Original
                       CMD(@"nmap", @"nmap:inWindow:"),
                       CMD(@"nmapclear", @"nmapclear:inWindow:"),
                       CMD(@"nmenu", @"menu:inWindow:"),
                       CMD(@"nnoremap", @"nnoremap:inWindow:"),
                       CMD(@"nnoremenu", @"menu:inWindow:"),
                       CMD(@"noremap", @"noremap:inWindow:"),
                       CMD(@"noautocmd", @"wrongmodifier:inWindow:"),
                       CMD(@"nohlsearch", @"nohlsearch:inWindow:"),
                       CMD(@"noreabbrev", @"abbreviate:inWindow:"),
                       CMD(@"noremenu", @"menu:inWindow:"),
                       CMD(@"normal", @"normal:inWindow:"),
                       CMD(@"number", @"print:inWindow:"),
                       CMD(@"nunmap", @"unmap:inWindow:"),
                       CMD(@"nunmenu", @"menu:inWindow:"),
                       CMD(@"open", @"open:inWindow:"),
                       CMD(@"oldfiles", @"oldfiles:inWindow:"),
                       CMD(@"omap", @"omap:inWindow:"),
                       CMD(@"omapclear", @"mapclear:inWindow:"),
                       CMD(@"omenu", @"menu:inWindow:"),
                       CMD(@"only", @"only:inWindow:"),
                       CMD(@"onoremap", @"onoremap:inWindow:"),
                       CMD(@"onoremenu", @"menu:inWindow:"),
                       CMD(@"options", @"options:inWindow:"),
                       CMD(@"ounmap", @"ounmap:inWindow:"),
                       CMD(@"ounmenu", @"menu:inWindow:"),
                       CMD(@"print", @"print:inWindow:"),
                       CMD(@"pcounterpart", @"pcounterpart:inWindow:"),    // XVim Original (This overrides original Vim's :pc command)
                       CMD(@"pclose", @"pclose:inWindow:"),
                       CMD(@"perl", @"perl:inWindow:"),
                       CMD(@"perldo", @"perldo:inWindow:"),
                       CMD(@"pedit", @"pedit:inWindow:"),
                       CMD(@"pissue", @"pissue:inWindow:"),    // XVim Original
                       CMD(@"pop", @"tag:inWindow:"),
                       CMD(@"popup", @"popup:inWindow:"),
                       CMD(@"ppop", @"ptag:inWindow:"),
                       CMD(@"preserve", @"preserve:inWindow:"),
                       CMD(@"previous", @"previous:inWindow:"),
                       CMD(@"promptfind", @"gui_mch_find_dialog:inWindow:"),
                       CMD(@"promptrepl", @"gui_mch_replace_dialog:inWindow:"),
                       CMD(@"profile", @"profile:inWindow:"),
                       CMD(@"profdel", @"breakdel:inWindow:"),
                       CMD(@"psearch", @"psearch:inWindow:"),
                       CMD(@"ptag", @"ptag:inWindow:"),
                       CMD(@"ptNext", @"ptag:inWindow:"),
                       CMD(@"ptfirst", @"ptag:inWindow:"),
                       CMD(@"ptjump", @"ptag:inWindow:"),
                       CMD(@"ptlast", @"ptag:inWindow:"),
                       CMD(@"ptnext", @"ptag:inWindow:"),
                       CMD(@"ptprevious", @"ptag:inWindow:"),
                       CMD(@"ptrewind", @"ptag:inWindow:"),
                       CMD(@"ptselect", @"ptag:inWindow:"),
                       CMD(@"put", @"put:inWindow:"),
                       CMD(@"pwd", @"pwd:inWindow:"),
                       CMD(@"python", @"python:inWindow:"),
                       CMD(@"pyfile", @"pyfile:inWindow:"),
                       CMD(@"quit", @"quit:inWindow:"),
                       CMD(@"quitall", @"quit_all:inWindow:"),
                       CMD(@"qall", @"quit_all:inWindow:"),
                       CMD(@"read", @"read:inWindow:"),
                       CMD(@"recover", @"recover:inWindow:"),
                       CMD(@"redo", @"redo:inWindow:"),
                       CMD(@"redir", @"redir:inWindow:"),
                       CMD(@"redraw", @"redraw:inWindow:"),
                       CMD(@"redrawstatus", @"redrawstatus:inWindow:"),
                       CMD(@"registers", @"reg:inWindow:"),
                       CMD(@"resize", @"resize:inWindow:"),
                       CMD(@"retab", @"retab:inWindow:"),
                       CMD(@"return", @"return:inWindow:"),
                       CMD(@"rewind", @"rewind:inWindow:"),
                       CMD(@"right", @"align:inWindow:"),
                       CMD(@"rightbelow", @"wrongmodifier:inWindow:"),
                       CMD(@"run",@"run:inWindow:"), // This is XVim original command
                       CMD(@"runtime", @"runtime:inWindow:"),
                       CMD(@"ruby", @"ruby:inWindow:"),
                       CMD(@"rubydo", @"rubydo:inWindow:"),
                       CMD(@"rubyfile", @"rubyfile:inWindow:"),
                       CMD(@"rviminfo", @"viminfo:inWindow:"),
                       CMD(@"substitute", @"sub:inWindow:"),
                       CMD(@"sNext", @"previous:inWindow:"),
                       CMD(@"sargument", @"argument:inWindow:"),
                       CMD(@"sall", @"all:inWindow:"),
                       CMD(@"sandbox", @"wrongmodifier:inWindow:"),
                       CMD(@"saveas", @"write:inWindow:"),
                       CMD(@"sbuffer", @"buffer:inWindow:"),
                       CMD(@"sbNext", @"bprevious:inWindow:"),
                       CMD(@"sball", @"buffer_all:inWindow:"),
                       CMD(@"sbfirst", @"brewind:inWindow:"),
                       CMD(@"sblast", @"blast:inWindow:"),
                       CMD(@"sbmodified", @"bmodified:inWindow:"),
                       CMD(@"sbnext", @"bnext:inWindow:"),
                       CMD(@"sbprevious", @"bprevious:inWindow:"),
                       CMD(@"sbrewind", @"brewind:inWindow:"),
                       CMD(@"scriptnames", @"scriptnames:inWindow:"),
                       CMD(@"scriptencoding", @"scriptencoding:inWindow:"),
                       CMD(@"scscope", @"scscope:inWindow:"),
                       CMD(@"set", @"set:inWindow:"),
                       CMD(@"setfiletype", @"setfiletype:inWindow:"),
                       CMD(@"setglobal", @"set:inWindow:"),
                       CMD(@"setlocal", @"set:inWindow:"),
                       CMD(@"sfind", @"splitview:inWindow:"),
                       CMD(@"sfirst", @"rewind:inWindow:"),
                       CMD(@"shell", @"shell:inWindow:"),
                       CMD(@"simalt", @"simalt:inWindow:"),
                       CMD(@"sign", @"sign:inWindow:"),
                       CMD(@"silent", @"wrongmodifier:inWindow:"),
                       CMD(@"sleep", @"sleep:inWindow:"),
                       CMD(@"slast", @"last:inWindow:"),
                       CMD(@"smagic", @"submagic:inWindow:"),
                       CMD(@"smap", @"smap:inWindow:"),
                       CMD(@"smapclear", @"smapclear:inWindow:"),
                       CMD(@"smenu", @"menu:inWindow:"),
                       CMD(@"snext", @"next:inWindow:"),
                       CMD(@"sniff", @"sniff:inWindow:"),
                       CMD(@"snomagic", @"submagic:inWindow:"),
                       CMD(@"snoremap", @"snoremap:inWindow:"),
                       CMD(@"snoremenu", @"menu:inWindow:"),
                       CMD(@"source", @"source:inWindow:"),
                       CMD(@"sort", @"sort:inWindow:"),
                       CMD(@"sort!", @"sort:inWindow:"),
                       CMD(@"split", @"splitview:inWindow:"),
                       CMD(@"spellgood", @"spell:inWindow:"),
                       CMD(@"spelldump", @"spelldump:inWindow:"),
                       CMD(@"spellinfo", @"spellinfo:inWindow:"),
                       CMD(@"spellrepall", @"spellrepall:inWindow:"),
                       CMD(@"spellundo", @"spell:inWindow:"),
                       CMD(@"spellwrong", @"spell:inWindow:"),
                       CMD(@"sprevious", @"previous:inWindow:"),
                       CMD(@"srewind", @"rewind:inWindow:"),
                       CMD(@"stop", @"stop:inWindow:"),
                       CMD(@"stag", @"stag:inWindow:"),
                       CMD(@"startinsert", @"startinsert:inWindow:"),
                       CMD(@"startgreplace", @"startinsert:inWindow:"),
                       CMD(@"startreplace", @"startinsert:inWindow:"),
                       CMD(@"stopinsert", @"stopinsert:inWindow:"),
                       CMD(@"stjump", @"stag:inWindow:"),
                       CMD(@"stselect", @"stag:inWindow:"),
                       CMD(@"sunhide", @"buffer_all:inWindow:"),
                       CMD(@"sunmap", @"sunmap:inWindow:"),
                       CMD(@"sunmenu", @"menu:inWindow:"),
                       CMD(@"suspend", @"stop:inWindow:"),
                       CMD(@"sview", @"splitview:inWindow:"),
                       CMD(@"swapname", @"swapname:inWindow:"),
                       CMD(@"syntax", @"syntax:inWindow:"),
                       CMD(@"syncbind", @"syncbind:inWindow:"),
                       CMD(@"t", @"copymove:inWindow:"),
                       CMD(@"tNext", @"tag:inWindow:"),
                       CMD(@"tag", @"tag:inWindow:"),
                       CMD(@"tags", @"tags:inWindow:"),
                       CMD(@"tab", @"wrongmodifier:inWindow:"),
                       CMD(@"tabclose", @"tabclose:inWindow:"),
                       CMD(@"tabdo", @"listdo:inWindow:"),
                       CMD(@"tabedit", @"splitview:inWindow:"),
                       CMD(@"tabfind", @"splitview:inWindow:"),
                       CMD(@"tabfirst", @"tabnext:inWindow:"),
                       CMD(@"tabmove", @"tabmove:inWindow:"),
                       CMD(@"tablast", @"tabnext:inWindow:"),
                       CMD(@"tabnext", @"tabnext:inWindow:"),
                       CMD(@"tabnew", @"splitview:inWindow:"),
                       CMD(@"tabonly", @"tabonly:inWindow:"),
                       CMD(@"tabprevious", @"tabnext:inWindow:"),
                       CMD(@"tabNext", @"tabnext:inWindow:"),
                       CMD(@"tabrewind", @"tabnext:inWindow:"),
                       CMD(@"tabs", @"tabs:inWindow:"),
                       CMD(@"tcl", @"tcl:inWindow:"),
                       CMD(@"tcldo", @"tcldo:inWindow:"),
                       CMD(@"tclfile", @"tclfile:inWindow:"),
                       CMD(@"tearoff", @"tearoff:inWindow:"),
                       CMD(@"test", @"test:inWindow:"), // XVim test case runner
                       CMD(@"tfirst", @"tag:inWindow:"),
                       CMD(@"throw", @"throw:inWindow:"),
                       CMD(@"tjump", @"tag:inWindow:"),
                       CMD(@"tlast", @"tag:inWindow:"),
                       CMD(@"tmenu", @"menu:inWindow:"),
                       CMD(@"tnext", @"tag:inWindow:"),
                       CMD(@"topleft", @"wrongmodifier:inWindow:"),
                       CMD(@"tprevious", @"tag:inWindow:"),
                       CMD(@"trewind", @"tag:inWindow:"),
                       CMD(@"try", @"try:inWindow:"),
                       CMD(@"tselect", @"tag:inWindow:"),
                       CMD(@"tunmenu", @"menu:inWindow:"),
                       CMD(@"undo", @"undo:inWindow:"),
                       CMD(@"undojoin", @"undojoin:inWindow:"),
                       CMD(@"undolist", @"undolist:inWindow:"),
                       CMD(@"unabbreviate", @"abbreviate:inWindow:"),
                       CMD(@"unhide", @"buffer_all:inWindow:"),
                       CMD(@"unlet", @"unlet:inWindow:"),
                       CMD(@"unlockvar", @"lockvar:inWindow:"),
                       CMD(@"unmap", @"unmap:inWindow:"),
                       CMD(@"unmenu", @"menu:inWindow:"),
                       CMD(@"unsilent", @"wrongmodifier:inWindow:"),
                       CMD(@"update", @"update:inWindow:"),
                       CMD(@"vglobal", @"global:inWindow:"),
                       CMD(@"version", @"version:inWindow:"),
                       CMD(@"verbose", @"wrongmodifier:inWindow:"),
                       CMD(@"vertical", @"wrongmodifier:inWindow:"),
                       CMD(@"visual", @"edit:inWindow:"),
                       CMD(@"view", @"edit:inWindow:"),
                       CMD(@"vimgrep", @"vimgrep:inWindow:"),
                       CMD(@"vimgrepadd", @"vimgrep:inWindow:"),
                       CMD(@"viusage", @"viusage:inWindow:"),
                       CMD(@"vmap", @"vmap:inWindow:"),
                       CMD(@"vmapclear", @"vmapclear:inWindow:"),
                       CMD(@"vmenu", @"menu:inWindow:"),
                       CMD(@"vnoremap", @"vnoremap:inWindow:"),
                       CMD(@"vnew", @"splitview:inWindow:"),
                       CMD(@"vnoremenu", @"menu:inWindow:"),
                       CMD(@"vsplit", @"vsplitview:inWindow:"),
                       CMD(@"vunmap", @"vunmap:inWindow:"),
                       CMD(@"vunmenu", @"menu:inWindow:"),
                       CMD(@"write", @"write:inWindow:"),
                       CMD(@"wNext", @"wnext:inWindow:"),
                       CMD(@"wall", @"wqall:inWindow:"),
                       CMD(@"while", @"while:inWindow:"),
                       CMD(@"winsize", @"winsize:inWindow:"),
                       CMD(@"wincmd", @"wincmd:inWindow:"),
                       CMD(@"windo", @"listdo:inWindow:"),
                       CMD(@"winpos", @"winpos:inWindow:"),
                       CMD(@"wnext", @"wnext:inWindow:"),
                       CMD(@"wprevious", @"wnext:inWindow:"),
                       CMD(@"wq", @"exit:inWindow:"),
                       CMD(@"wqall", @"wqall:inWindow:"),
                       CMD(@"wsverb", @"wsverb:inWindow:"),
                       CMD(@"wviminfo", @"viminfo:inWindow:"),
                       CMD(@"xccmd" , @"xccmd:inWindow:"),
                       CMD(@"xcmenucmd" , @"xcmenucmd:inWindow:"),   // XVim original
                       CMD(@"xctabctrl", @"xctabctrl:inWindow:"),
                       CMD(@"xhelp", @"xhelp:inWindow:"), // Quick Help (XVim Original)
                       CMD(@"xit", @"exit:inWindow:"),
                       CMD(@"xall", @"wqall:inWindow:"),
                       CMD(@"xmap", @"xmap:inWindow:"),
                       CMD(@"xmapclear", @"xmapclear:inWindow:"),
                       CMD(@"xmenu", @"menu:inWindow:"),
                       CMD(@"xnoremap", @"xnoremap:inWindow:"),
                       CMD(@"xnoremenu", @"menu:inWindow:"),
                       CMD(@"xunmap", @"xunmap:inWindow:"),
                       CMD(@"xunmenu", @"menu:inWindow:"),
                       CMD(@"yank", @"operators:inWindow:"),
                       CMD(@"z", @"z:inWindow:"),
                       CMD(@"!", @"bang:inWindow:"),
                       CMD(@"#", @"print:inWindow:"),
                       CMD(@"&", @"sub:inWindow:"),
                       CMD(@"*", @"at:inWindow:"),
                       CMD(@"<", @"operators:inWindow:"),
                       CMD(@"=", @"equal:inWindow:"),
                       CMD(@">", @"operators:inWindow:"),
                       CMD(@"@", @"at:inWindow:"),
                       CMD(@"Next", @"previous:inWindow:"),
                       CMD(@"Print", @"print:inWindow:"),
                       CMD(@"X", @"X:inWindow:"),
                       CMD(@"~", @"sub:inWindow:"),
					   nil];
    }
    return self;
}


// This method correnspons parsing part of get_address in ex_cmds.c
- (NSUInteger)getAddress:(unichar*)parsing :(unichar**)cmdLeft inWindow:(XVimWindow*)window
{
    NSTextView* view = [window sourceView];
    //DVTFoldingTextStorage* storage = [view textStorage];
    //TRACE_LOG(@"Storage Class:%@", NSStringFromClass([storage class]));
    NSUInteger addr = NSNotFound;
    NSUInteger begin = view.selectionBegin;
    NSUInteger end = view.insertionPoint;
    unichar* tmp;
    NSUInteger count;
    unichar mark;
    
    // Parse base addr (line number)
    switch (*parsing)
    {
        case '.':
            parsing++;
            addr = [view.textStorage xvim_lineNumberAtIndex:begin];
            break;
        case '$':			    /* '$' - last line */
            parsing++;
            addr = [view.textStorage xvim_numberOfLines];
            break;
        case '\'':
            // XVim does support only '< '> marks for visual mode
            mark = parsing[1];
            if( '<' == mark ){
                addr = [view.textStorage xvim_lineNumberAtIndex:begin];
                parsing+=2;
            }else if( '>' == mark ){
                addr = [view.textStorage xvim_lineNumberAtIndex:end];
                parsing+=2;
            }else{
                // Other marks or invalid character. XVim does not support this.
            }
            break;
        case '/':
        case '?':
        case '\\':
            // XVim does not support using search in range at the moment
            // XVim does not support using search in range at the moment
        default:
            tmp = parsing;
            count = 0;
            while( isDigit(*parsing) ){
                parsing++;
                count++;
            }
            addr = (unsigned int)[[NSString stringWithCharacters:tmp length:count] intValue];
            if( 0 == addr ){
                addr = NSNotFound;
            }
    }
    
    // Parse additional modifier for addr ( ex. $-10 means 10 line above from end of file. Parse '-10' part here )
    for (;;)
    {
        // Skip whitespaces
        while( isWhitespace(*parsing) ){
            parsing++;
        }
        
        unichar c = *parsing;
        unichar i;
        NSUInteger n;
        if (c != '-' && c != '+' && !isDigit(c)) // Handle '-' or '+' or degits only
            break;
        
        if (addr == NSNotFound){
            //addr = [view lineNumber:begin]; // This should be current cursor posotion
        }
        
        // Determine if its + or -
        if (isDigit(c)){
            i = '+';		/* "number" is same as "+number" */
        }else{
            i = c;
            parsing++;
        }
        
        if (!isDigit(*parsing)){	/* '+' is '+1', but '+0' is not '+1' */
            n = 1;
        }
        else{
            tmp = parsing;
            count = 0;
            while( isDigit(*parsing) ){
                parsing++;
                count++;
            }
            n = (unsigned int)[[NSString stringWithCharacters:tmp length:count] intValue];
        }
        
        // Calc the address from base
        if (i == '-')
            addr -= n;
        else
            addr += n;
    }
    
    *cmdLeft = parsing;
    return addr;
}

// This method correnspons parsing part of do_one_cmd in ex_docmd.c in Vim
// What Vim does in this function is followings
/*
 * 1. skip comment lines and leading space
 * 2. handle command modifiers
 * 3. parse range
 * 4. parse command
 * 5. parse arguments
 * 6. switch on command name
 */

/*
 * But XVim implements minimum set of above processes at thee moment
 * Command line XVim supports are following format
 *     [range][command] [arguments]
 * [range] is [addr][,addr][,addr]...     separated by ';' is not supported at the moment
 * [addr] only supports digits or %,.,$,'<,'>, and +- modifiers
 * Multiple commands separated by '|' is not supported at the moment
 * Space is needed between [command] and [arguments]
 * 
 */

- (XVimExArg*)parseCommand:(NSString*)cmd inWindow:(XVimWindow*)window
{
    XVimExArg* exarg = [[XVimExArg alloc] init]; 
    NSUInteger len = [cmd length];
    
    // Create unichar array to parse. Its easier
    NSMutableData* dataCmd = [NSMutableData dataWithLength:(len+1)*sizeof(unichar)];
    unichar* pCmd = (unichar*)[dataCmd bytes];
    [cmd getCharacters:pCmd range:NSMakeRange(0,len)];
    pCmd[len] = 0; // NULL terminate
     
    unichar* parsing = pCmd;
    
    // 1. skip comment lines and leading space ( XVim does not handling commnet lines )
    for( NSUInteger i = 0; i < len && ( isWhitespace(*parsing) || *parsing == ':' ); i++,parsing++ );
    
    // 2. handle command modifiers
    // XVim does not support command mofifiers at the moment
    
    // 3. parse range
    exarg.lineBegin = NSNotFound;
    exarg.lineEnd = NSNotFound;
	
    NSTextView* view = [window sourceView];
    for(;;){
        NSUInteger addr = [self getAddress:parsing :&parsing inWindow:window];
        if( NSNotFound == addr ){
            if( *parsing == '%' ){ // XVim only supports %
                exarg.lineBegin = 1;
                exarg.lineEnd = [view.textStorage xvim_numberOfLines];
                parsing++;
            }
        }else{
            exarg.lineEnd = addr;
        }
        
        if( exarg.lineBegin == NSNotFound ){ // If its first range 
            exarg.noRangeSpecified = YES;
            exarg.lineBegin = exarg.lineEnd;
        }
        else {
            exarg.noRangeSpecified = NO;
        }
        
        if( *parsing != ',' ){
            break;
        }
        
        parsing++;
    }
    
    if( exarg.lineBegin == NSNotFound ){
        // No range expression found. Use current line as range
        exarg.lineBegin = [view.textStorage xvim_lineNumberAtIndex:view.insertionPoint];
        exarg.lineEnd =  exarg.lineBegin;
    }
    
    // 4. parse command
    // In window command and its argument must be separeted by space
    unichar* tmp = parsing;
    NSUInteger count = 0;
    if (*parsing == '!') {
        parsing++; count++;
    }
    else
    while( isAlpha(*parsing) ){
        parsing++;
        count++;
    }

    if( 0 != count ){
        exarg.cmd = [NSString stringWithCharacters:tmp length:count];
    }else{
        // no command
        exarg.cmd = nil;
    }
    
    while( isWhitespace(*parsing)  ){
        parsing++;
    }
    
    // 5. parse arguments
    tmp = parsing;
    count = 0;
    while( *parsing != 0 ){
        count++;
        parsing++;
    }
    if( 0 != count ){
        exarg.arg = [NSString stringWithCharacters:tmp length:count];
    }else{
        // no command
        exarg.arg = nil;
    }
    
    return exarg;
}

// This method corresponds to do_one_cmd in ex_docmd.c in Vim
- (void)executeCommand:(NSString*)cmd inWindow:(XVimWindow*)window
{
    // cmd INCLUDE ":" character
    
    if( [cmd length] == 0 ){
        ERROR_LOG(@"command string empty");
        return;
    }
    
    cmd = [cmd stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    // Actual parsing is done in following method.
    XVimExArg* exarg = [self parseCommand:cmd inWindow:window];
    if( exarg.cmd == nil ) {
		NSTextView* srcView = [window sourceView];
        NSTextStorage* storage = srcView.textStorage;
		
        // Jump to location
        NSUInteger pos = [storage xvim_indexOfLineNumber:exarg.lineBegin column:0];
        if( NSNotFound == pos ){
            pos = [srcView.textStorage xvim_indexOfLineNumber:[srcView.textStorage xvim_numberOfLines] column:0];
        }
        NSUInteger pos_wo_space = [srcView.textStorage xvim_nextNonblankInLineAtIndex:pos allowEOL:NO];
        if( NSNotFound == pos_wo_space ){
            pos_wo_space = pos;
        }
        [srcView setSelectedRange:NSMakeRange(pos_wo_space,0)];
        [srcView xvim_scrollTo:[window.sourceView insertionPoint]];
        return;
    }
    
    // switch on command name
    for( XVimExCmdname* cmdname in _excommands ){
        if( [cmdname.cmdName hasPrefix:[exarg cmd]] ){
            SEL method = NSSelectorFromString(cmdname.methodName);
            if( [self respondsToSelector:method] ){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:method withObject:exarg withObject:window];
#pragma clang diagnostic pop
                break;
            }
        }
    }
    
    return;
}

//////////////////////////////////////////////////////////
//   Commands  !!Please keep them alphabetical order!!  //
//////////////////////////////////////////////////////////

- (void)commit:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(commitCommand:) to:nil from:self];
}

- (void)cmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self mapMode:XVIM_MODE_CMDLINE withArgs:args remap:YES];
}

- (void)cnoremap:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self mapMode:XVIM_MODE_CMDLINE withArgs:args remap:NO];
}

- (void)cunmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self unmapMode:XVIM_MODE_CMDLINE withArgs:args];
}

- (void)cmapclear:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self mapClearMode:XVIM_MODE_CMDLINE];
}

- (void)cquit:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    [XVimLastActiveWorkspaceTabController() xvim_closeCurrentEditor];
}

- (void)debug:(XVimExArg*)args inWindow:(XVimWindow*)window{
    NSMutableArray* params = [NSMutableArray arrayWithArray:[args.arg componentsSeparatedByString:@" "]];
    if( [params count] == 0 ){
        return;
    }
    XVimDebug* debug = [[XVimDebug alloc] init];
    NSString* selector = [NSString stringWithFormat:@"%@:withWindow:",[params objectAtIndex:0]];
    [params removeObjectAtIndex:0];
    if( [debug respondsToSelector:NSSelectorFromString(selector)] ){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [debug performSelector:NSSelectorFromString(selector) withObject:params withObject:window];
#pragma clang diagnostic pop
    }
}

- (void)exit:(XVimExArg*)args inWindow:(XVimWindow*)window{ // :wq
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
    [NSApp sendAction:@selector(closeDocument:) to:nil from:self];
}

- (void)imap:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self mapMode:XVIM_MODE_INSERT withArgs:args remap:YES];
}

- (void)inoremap:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self mapMode:XVIM_MODE_INSERT withArgs:args remap:NO];
}

- (void)iunmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self unmapMode:XVIM_MODE_INSERT withArgs:args];
}

- (void)imapclear:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self mapClearMode:XVIM_MODE_INSERT];
}

- (void)make:(XVimExArg*)args inWindow:(XVimWindow*)window{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"b" charactersIgnoringModifiers:@"b" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

// Private
- (void)writeMapsToConsoleWithFirstLetter:(NSString*)f forMapMode:(XVIM_MODE)mode{
    // Show map list in console
    XVimKeymap* map =  [[XVim instance] keymapForMode:mode];
    [map enumerateKeymaps:^(NSString *mapFrom, NSString *mapTo){
        [[XVim instance] writeToConsole:[NSString stringWithFormat:@"%@ %-10s %s",f, [mapFrom UTF8String], [mapTo UTF8String]] ];
    }];
}

- (void)map:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"n" forMapMode:XVIM_MODE_NORMAL];
        [self writeMapsToConsoleWithFirstLetter:@"o" forMapMode:XVIM_MODE_OPERATOR_PENDING];
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_VISUAL];
        return;
    }
	[self mapMode:XVIM_MODE_NORMAL withArgs:args remap:YES];
	[self mapMode:XVIM_MODE_OPERATOR_PENDING withArgs:args remap:YES];
	[self mapMode:XVIM_MODE_VISUAL withArgs:args remap:YES];
}

- (void)noremap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"n" forMapMode:XVIM_MODE_NORMAL];
        [self writeMapsToConsoleWithFirstLetter:@"o" forMapMode:XVIM_MODE_OPERATOR_PENDING];
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_VISUAL];
        return;
    }
	[self mapMode:XVIM_MODE_NORMAL withArgs:args remap:NO];
	[self mapMode:XVIM_MODE_OPERATOR_PENDING withArgs:args remap:NO];
	[self mapMode:XVIM_MODE_VISUAL withArgs:args remap:NO];
}

- (void)unmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self unmapMode:XVIM_MODE_NORMAL withArgs:args];
	[self unmapMode:XVIM_MODE_OPERATOR_PENDING withArgs:args];
	[self unmapMode:XVIM_MODE_VISUAL withArgs:args];
}

- (void)mapclear:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self mapClearMode:XVIM_MODE_NORMAL];
	[self mapClearMode:XVIM_MODE_OPERATOR_PENDING];
	[self mapClearMode:XVIM_MODE_VISUAL];
}

- (void)mapMode:(XVIM_MODE)mode withArgs:(XVimExArg*)args remap:(BOOL)remap{
	NSString *argString = args.arg;
	NSScanner *scanner = [NSScanner scannerWithString:argString];
	
	NSMutableArray *subStrings = [[NSMutableArray alloc] init];
	NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
	for (;;){
		NSString *string;
		[scanner scanCharactersFromSet:ws intoString:&string];
		if (scanner.isAtEnd) {
            break;
        }
		[scanner scanUpToCharactersFromSet:ws intoString:&string];
		[subStrings addObject:string];
	}
  
	if (subStrings.count >= 2) {
		NSString *fromString = [subStrings objectAtIndex:0];
        [subStrings removeObjectAtIndex:0];
        // Todo: ":map a b  " must be mapped to "a" -> "b<space><space>"
		NSString *toString = [subStrings componentsJoinedByString:@" "]; // get all args seperate by space
		
		if (fromString.length > 0 && toString.length > 0){
			XVimKeymap *keymap = [[XVim instance] keymapForMode:mode];
			[keymap map:XVimStringFromKeyNotation(fromString) to:XVimStringFromKeyNotation(toString) withRemap:remap];
		}
	}
}

- (void)unmapMode:(XVIM_MODE)mode withArgs:(XVimExArg*)args{
	NSString *argString = args.arg;
	NSScanner *scanner = [NSScanner scannerWithString:argString];
	
	NSMutableArray *subStrings = [[NSMutableArray alloc] init];
	NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
	for (;;){
		NSString *string;
		[scanner scanCharactersFromSet:ws intoString:&string];
		if (scanner.isAtEnd) {
            break;
        }
		[scanner scanUpToCharactersFromSet:ws intoString:&string];
		[subStrings addObject:string];
	}
  
	if (subStrings.count >= 1) {
		NSString *fromString = [subStrings objectAtIndex:0];
		if (fromString.length > 0 ){
			XVimKeymap *keymap = [[XVim instance] keymapForMode:mode];
			[keymap unmap:XVimStringFromKeyNotation(fromString)];
		}
	}
    
}

- (void)mapClearMode:(XVIM_MODE)mode{
    XVimKeymap *keymap = [[XVim instance] keymapForMode:mode];
    [keymap clear];
}

- (void)marks:(XVimExArg*)args inWindow:(XVimWindow*)window{ // This is currently impelemented for debugging purpose
    NSString* local = [[XVim instance].marks dumpMarksForDocument:window.sourceView.documentURL.path];
    NSString* file = [[XVim instance].marks dumpFileMarks];
    [[XVim instance] writeToConsole:@"----LOCAL MARKS----\n%@", local];
    [[XVim instance] writeToConsole:@"----FILE MARKS----\n%@", file];
}

- (void)ncounterpart:(XVimExArg*)args inWindow:(XVimWindow*)window{
    // To make forcus proper
    // We must make forcus back to editor first then invoke the command.
    // This is because I do not know how to move focus on newly visible text editor by invoking this command.
    // Without this focus manipulation the focus after the command does not goes to the text editor
    [window setForcusBackToSourceView];
    [NSApp sendAction:@selector(jumpToNextCounterpart:) to:nil from:self];
}

- (void)nohlsearch:(XVimExArg*)args inWindow:(XVimWindow*)window{
    NSTextView* view = [window sourceView];
    [view setNeedsUpdateFoundRanges:YES];
    [view xvim_clearHighlightText];
}

- (void)nissue:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(jumpToNextIssue:) to:nil from:self];
}

- (void)nmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_NORMAL];
        return;
    }
	[self mapMode:XVIM_MODE_NORMAL withArgs:args remap:YES];
}

- (void)nnoremap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_NORMAL];
        return;
    }
	[self mapMode:XVIM_MODE_NORMAL withArgs:args remap:NO];
}

- (void)nunmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self unmapMode:XVIM_MODE_NORMAL withArgs:args];
}

- (void)nmapclear:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self mapClearMode:XVIM_MODE_NORMAL];
}

- (void)omap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_OPERATOR_PENDING];
        return;
    }
	[self mapMode:XVIM_MODE_OPERATOR_PENDING withArgs:args remap:YES];
}

- (void)only:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    [XVimLastActiveWorkspaceTabController() xvim_closeOtherEditors];
}

- (void)onoremap:(XVimExArg*)args inWindow:(XVimWindow*)window{
	[self mapMode:XVIM_MODE_OPERATOR_PENDING withArgs:args remap:NO];
}

- (void)ounmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_OPERATOR_PENDING];
        return;
    }
    [self unmapMode:XVIM_MODE_OPERATOR_PENDING withArgs:args];
}

- (void)omapclear:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self mapClearMode:XVIM_MODE_OPERATOR_PENDING];
}

- (void)pcounterpart:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    [NSApp sendAction:@selector(jumpToPreviousCounterpart:) to:nil from:self];
}

- (void)pissue:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(jumpToPreviousIssue:) to:nil from:self];
}

- (void)quit:(XVimExArg*)args inWindow:(XVimWindow*)window{ // :q
    [window setForcusBackToSourceView];
    [XVimLastActiveWorkspaceTabController() xvim_closeCurrentEditor];
}

- (void)reg:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [[[XVim instance] registerManager] enumerateRegisters:^(NSString* name, XVimRegister* reg){
        if( reg.string.length != 0 ){
            [[XVim instance] writeToConsole:@"\"%@   %@", name, XVimKeyNotationFromXVimString(reg.string) ];
        }
    }];
}

- (void)run:(XVimExArg*)args inWindow:(XVimWindow*)window{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"r" charactersIgnoringModifiers:@"r" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

- (void)set:(XVimExArg*)args inWindow:(XVimWindow*)window{
    NSString* setCommand = [args.arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSTextView* srcView = [window sourceView];
	XVimOptions* options = [[XVim instance] options];
    
    if( [setCommand rangeOfString:@"="].location != NSNotFound ){
        // "set XXX=YYY" form
		NSUInteger idx = [setCommand rangeOfString:@"="].location;
		NSString *name = [[setCommand substringToIndex:idx] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSString *value = [[setCommand substringFromIndex:idx + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		[options setOption:name value:value];
        
    }else if( [setCommand hasPrefix:@"no"] ){
        // "set noXXX" form
        NSString* prop = [setCommand substringFromIndex:2];
        [options setOption:prop value:[NSNumber numberWithBool:NO]];
    }else{
        // "set XXX" form
        [options setOption:setCommand value:[NSNumber numberWithBool:YES]];
    }
    
    if( [setCommand isEqualToString:@"wrap"] ){
        [srcView xvim_setWrapsLines:YES];
    }
    else if( [setCommand isEqualToString:@"nowrap"] ){
        [srcView xvim_setWrapsLines:NO];
    } else if( [setCommand isEqualToString:@"list!"] ){
      [NSApp sendAction:@selector(toggleInvisibleCharactersShown:) to:nil from:self];
    }
}

- (void)sort:(XVimExArg *)args inWindow:(XVimWindow *)window{
    NSTextView *view = [window sourceView];
    
    NSString *cmdString = [[args cmd] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *argsString = [args arg];
    XVimSortOptions options = 0;
    
    if ([cmdString characterAtIndex:[cmdString length] - 1] == '!') {
        options |= XVimSortOptionReversed;
    }
    
    if (argsString) {
        #define STR_CONTAINS_ARG(str, arg) ([str rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:arg]].location != NSNotFound)
        if (STR_CONTAINS_ARG(argsString, @"n")) {
            options |= XVimSortOptionNumericSort;
        }
        if (STR_CONTAINS_ARG(argsString, @"i")) {
            options |= XVimSortOptionIgnoreCase;
        }
        if (STR_CONTAINS_ARG(argsString, @"u")) {
            options |= XVimSortOptionRemoveDuplicateLines;
        }
    }
    
    [view xvim_sortLinesFrom:args.lineBegin to:args.lineEnd withOptions:options];
}

- (void)splitview:(XVimExArg *)args inWindow:(XVimWindow *)window{
    [XVimLastActiveWorkspaceTabController() xvim_addEditorHorizontally];
}

- (void)sub:(XVimExArg*)args inWindow:(XVimWindow*)window{
	XVimSearch *searcher = [[XVim instance] searcher];
    [searcher substitute:args.arg from:args.lineBegin to:args.lineEnd inWindow:window];
}

// When I use tab cmds, the focus of text edit lost, against my will.
// Some cmds need keeping focus. Some need resign focus. I tried but failed.
// I hope to do the most work without mouse.
- (void)tabnext:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView]; // add by dengjinlong
    [NSApp sendAction:@selector(selectNextTab:) to:nil from:self];
}

- (void)tabprevious:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    [NSApp sendAction:@selector(selectPreviousTab:) to:nil from:self];
}

- (void)tabclose:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    [NSApp sendAction:@selector(closeCurrentTab:) to:nil from:self];
}

- (void)test:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [[XVim instance].testRunner selectCategories:@[args.arg]];
    [[XVim instance].testRunner runTest];
}


- (void)undo:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window.sourceView.undoManager undo];
    return ;
}

- (void)vmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_VISUAL];
        return;
    }
	[self mapMode:XVIM_MODE_VISUAL withArgs:args remap:YES];
}

- (void)vnoremap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    if( args.arg.length == 0 ){
        [self writeMapsToConsoleWithFirstLetter:@"v" forMapMode:XVIM_MODE_VISUAL];
        return;
    }
	[self mapMode:XVIM_MODE_VISUAL withArgs:args remap:NO];
}

- (void)vunmap:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self unmapMode:XVIM_MODE_VISUAL withArgs:args];
}

- (void)vmapclear:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [self mapClearMode:XVIM_MODE_VISUAL];
}

- (void)vsplitview:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [XVimLastActiveWorkspaceTabController() xvim_addEditorVertically];
}

- (void)write:(XVimExArg*)args inWindow:(XVimWindow*)window{ // :w
    [NSApp sendAction:@selector(ide_saveDocument:) to:nil from:self];
}

- (NSMenuItem*)findMenuItemIn:(NSMenu*)menu forAction:(NSString*)actionName{
    if( nil == menu ){
        menu = [NSApp mainMenu];
    }
    for(NSMenuItem* mi in [menu itemArray] ){
        TRACE_LOG(@"%@", mi.title);
        if( [mi action] == NSSelectorFromString(actionName) ){
            return mi;
        }
        if( nil != [mi submenu] ){
            NSMenuItem* found = [self findMenuItemIn:[mi submenu] forAction:actionName];
            if( nil != found ){
                return found;
            }
        }
    }
    return nil;
}

- (void)xccmd:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    NSMenuItem* item = [self findMenuItemIn:nil forAction:[[args arg] stringByAppendingString:@":"]];
    if( nil != item ){
        //Sending some actions(followings) without "from:" crashes Xcode.
        //Title:Show File Template Library    Action:showLibraryWithChoiceFromSender:
        //Title:Show Code Snippet Library    Action:showLibraryWithChoiceFromSender:
        //Title:Show Object Library    Action:showLibraryWithChoiceFromSender:
        //Title:Show Media Library    Action:showLibraryWithChoiceFromSender:
        [NSApp sendAction:item.action to:item.target from:item];
    }
}

- (NSMenuItem*)findMenuItemIn:(NSMenu*)menu forTitle:(NSString*)titleName{
    if( nil == menu ){
        menu = [NSApp mainMenu];
    }
    for(NSMenuItem* mi in [menu itemArray] ){
        if( [mi.title localizedCaseInsensitiveCompare:titleName] == NSOrderedSame ){
            return mi;
        }
        if( nil != [mi submenu] ){
            NSMenuItem* found = [self findMenuItemIn:[mi submenu] forTitle:titleName];
            if( nil != found ){
                return found;
            }
        }
    }
    return nil;
}

// add by dengjinlong
// I upload my .xvim to https://github.com/dengcqw/XVim-config-file FYI
- (void)xcmenucmd:(XVimExArg*)args inWindow:(XVimWindow*)window{
// I comment below, to resign focus, but failed. I also simulate mouse click.
// simulate mouse click - [NSMenu performActionForItemAtIndex:]
// It is better to open Utilities, and focus its text field.
// [window setForcusBackToSourceView];
    NSMenuItem* item = [self findMenuItemIn:nil forTitle:args.arg];
   if( nil == item || item.action == @selector(submenuAction:)){
       return;
   }
    
    // Below if-else achieves the same goal. I'm not sure the better one.
    IDEWorkspaceTabController* ctrl = XVimLastActiveWorkspaceTabController();
    if( [ctrl respondsToSelector:item.action] ){
        NSLog(@"IDEWorkspaceTabController perform action");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [ctrl performSelector:item.action withObject:item];
#pragma clang diagnostic pop
    } else {
        [NSApp sendAction:item.action to:item.target from:item];
        NSLog(@"menu perform action");
    }
}

- (void)xctabctrl:(XVimExArg*)args inWindow:(XVimWindow*)window{
    IDEWorkspaceTabController* ctrl = XVimLastActiveWorkspaceTabController();
    if( [ctrl respondsToSelector:NSSelectorFromString(args.arg)] ){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [ctrl performSelector:NSSelectorFromString(args.arg) withObject:self];
#pragma clang diagnostic pop
    }
}

- (void)xhelp:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(showQuickHelp:) to:nil from:self];
}


-(void)bang:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    NSUInteger firstFilteredLine = args.lineBegin;
    NSString* selectedText = nil;
    NSUInteger inputStartLocation = 0;
    NSUInteger inputEndLocation;

    if (!args.noRangeSpecified && args.lineBegin != NSNotFound && args.lineEnd != NSNotFound)
    {
        // Find the position to start searching
        inputStartLocation = [window.sourceView.textStorage xvim_indexOfLineNumber:args.lineBegin column:0];
        if( NSNotFound == inputStartLocation){ return; }
        
        // Find the position to end the searching
        inputEndLocation = [window.sourceView.textStorage xvim_indexOfLineNumber:args.lineEnd+1 column:0]; // Next line of the end of range.
        if( NSNotFound == inputEndLocation ){ inputEndLocation = [[[window sourceView] string] length]; }
        selectedText = [[window.sourceView.textStorage string] substringWithRange:NSMakeRange(inputStartLocation,inputEndLocation-inputStartLocation)];
        [window.sourceView setSelectedRange:NSMakeRange(inputStartLocation, inputEndLocation-inputStartLocation) ];
    }

    NSURL* documentURL = [ window.sourceView documentURL ];
    NSString* runDir   = @"/";

    if ([documentURL isFileURL])
    {
        NSString* documentPath = [documentURL path];
        runDir = [[documentURL URLByDeletingLastPathComponent] path];
        NSDictionary* contextForExCmd = [ NSDictionary dictionaryWithObjectsAndKeys :
                                          [ self _altFilename:documentPath ], @"#"
                                          , documentPath ?             documentPath : @"", @"%"
                                          , nil];
        [ self _expandSpecialExTokens:args contextDict:contextForExCmd];
    }

    NSString* scriptReturn = [ XVimTaskRunner runScript:args.arg
                                              withInput:selectedText
                                            withTimeout:EXTERNAL_COMMAND_TIMEOUT_SECS
                                           runDirectory:runDir
                                               colWidth:window.commandLine.quickFixColWidth];
    if (scriptReturn != nil)
    {
        if (args.noRangeSpecified)
        {
            // No text range was specified -- open quickfix window to display the result
            [ window showQuickfixWithString:scriptReturn completionHandler:^{
                [window.currentWorkspaceWindow makeFirstResponder:window.sourceView];
            } ];
        }
        else
        {
            // A text range was specified -- replace the range with the output of the command
            [ window.sourceView insertText:scriptReturn ];

            if (firstFilteredLine != NSNotFound)
            {
                [window.sourceView setSelectedRange:NSMakeRange(inputStartLocation, 1)];
            }
        }
    }
}

// Really rubbish way of getting the alt filename
-(NSString*)_altFilename:(NSString *)filename
{
    if (!filename)
    {
        return @"";
    }
    NSString* extension = [ filename pathExtension ];
    if (!extension || [extension length]==0)
    {
        return @"";
    }
    if ([extension isEqualToString:@"m"] || [extension isEqualToString:@"mm"] || [extension isEqualToString:@"c"] )
    {
        return [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"h" ];
    }
    else if ([extension isEqualToString:@"h"])
    {
        return [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"m" ];
    }
    return @"";
    
}


// Expands special ex command 'tokens', as described in cmdline-special of the vim docs
// :., :~, :s and :gs are not supported yet
-(void)_expandSpecialExTokens:(XVimExArg *)arg contextDict:(NSDictionary *)ctx
{
    if (!arg.arg || [arg.arg length]==0) {
        return;
    }
    NSError*error=nil;
    NSRegularExpression* regex = [ NSRegularExpression regularExpressionWithPattern:@"(%|#)(:p|:~|:h|:r|:t|:e|:\\.)*"
                                                                            options:0
                                                                              error:&error];
    NSMutableString* resultStr = [ NSMutableString string ];
    __block NSRange remainderRange = NSMakeRange(0, [arg.arg length]);
    [ regex enumerateMatchesInString:arg.arg
                             options:NSMatchingReportCompletion
                               range:remainderRange
                          usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		 if ( result == nil)
		 {
			 [ resultStr appendString:[ arg.arg substringWithRange:remainderRange ]];
		 }
		 else
		 {
			 // % or #
			 NSRange lastMatchedRange =[ result rangeAtIndex:1 ];
			 NSString* matchedToken = [arg.arg substringWithRange:lastMatchedRange ];
			 NSString* substituteValue = [ ctx objectForKey:matchedToken ];
			 if (!substituteValue)
			 {
				 substituteValue = matchedToken;
			 }
			 NSUInteger matchIdx = 2;
			 //DEBUG_LOG(@"Number of matched ranges = %d", [result numberOfRanges] );
			 while (matchIdx < [ result numberOfRanges]) {
				 NSRange nextMatchedRange = [ result rangeAtIndex:matchIdx ];
				 if (nextMatchedRange.location != NSNotFound)
				 {
					 NSUInteger matchedPos = lastMatchedRange.location + lastMatchedRange.length ;
					 // This is the REAL matched range...to my eyes, NSRegularExpression has a bug
					 NSRange matchedRange = NSMakeRange(matchedPos, nextMatchedRange.location+nextMatchedRange.length-matchedPos);
					 NSString* matchedToken = [arg.arg substringWithRange:matchedRange];
					 //DEBUG_LOG(@"Modifiers at range %@ = %@", NSStringFromRange(matchedRange), matchedToken );
					 for (NSUInteger modIdx = 1; modIdx < [matchedToken length]; modIdx++,modIdx++) {
						 char modifier = (char)[matchedToken characterAtIndex:modIdx ];
						 switch (modifier) {
							 case 'p': // return full 'path' (expand tilde, etc.)
								 substituteValue = [ substituteValue stringByStandardizingPath ];
								 break;
							 case 'h': // return 'head' of path (chop off last component)
								 substituteValue = [ substituteValue stringByDeletingLastPathComponent ];
								 break;
							 case 'r': // 'root' of filename (remove extension)
								 substituteValue = [ substituteValue stringByDeletingPathExtension ];
								 break;
							 case 't': // 'tail' of filename (last path component)
								 substituteValue = [ substituteValue lastPathComponent ];
								 break;
							 case 'e': // 'extension' of filename
								 substituteValue = [ substituteValue pathExtension ];
								 break;
							 default:
								 break;
						 }
					 }
					 lastMatchedRange = matchedRange;
				 }
				 matchIdx++;
			 }
			 NSUInteger matchStart = [ result range ].location;
			 NSUInteger matchLen = [ result range ].length;
			 NSRange firstHalfRange = NSMakeRange(remainderRange.location, matchStart-remainderRange.location);
			 [ resultStr appendFormat:@"%@%@", [arg.arg substringWithRange:firstHalfRange],substituteValue];
			 remainderRange.location = matchStart + matchLen ;
			 remainderRange.length = [arg.arg length] - remainderRange.location ;
		 }
    }];
    arg.arg = resultStr;
}

@end
