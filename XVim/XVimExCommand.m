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
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "NSString+VimHelper.h"
#import "Logger.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimOptions.h"
#import "IDEKit.h"

@implementation XVimExArg
@synthesize arg,cmd,forceit,lineBegin,lineEnd,addr_count;
@end

@implementation XVimExCmdname
@synthesize cmdName,methodName;

-(id)initWithCmd:(NSString*)cmd method:(NSString*)method{
    if( self = [super init] ){
        cmdName = [cmd retain];
        methodName = [method retain];
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
                       CMD(@"cmap", @"map:inWindow:"),
                       CMD(@"cmapclear", @"mapclear:inWindow:"),
                       CMD(@"cmenu", @"menu:inWindow:"),
                       CMD(@"cnext", @"cnext:inWindow:"),
                       CMD(@"cnewer", @"qf_age:inWindow:"),
                       CMD(@"cnfile", @"cnext:inWindow:"),
                       CMD(@"cnoremap", @"map:inWindow:"),
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
                       CMD(@"cunmap", @"unmap:inWindow:"),
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
                       CMD(@"imapclear", @"mapclear:inWindow:"),
                       CMD(@"imenu", @"menu:inWindow:"),
                       CMD(@"inoremap", @"map:inWindow:"),
                       CMD(@"inoreabbrev", @"abbreviate:inWindow:"),
                       CMD(@"inoremenu", @"menu:inWindow:"),
                       CMD(@"intro", @"intro:inWindow:"),
                       CMD(@"isearch", @"findpat:inWindow:"),
                       CMD(@"isplit", @"findpat:inWindow:"),
                       CMD(@"iunmap", @"unmap:inWindow:"),
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
                       CMD(@"nmapclear", @"mapclear:inWindow:"),
                       CMD(@"nmenu", @"menu:inWindow:"),
                       CMD(@"nnoremap", @"map:inWindow:"),
                       CMD(@"nnoremenu", @"menu:inWindow:"),
                       CMD(@"noremap", @"map:inWindow:"),
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
                       CMD(@"onoremap", @"map:inWindow:"),
                       CMD(@"onoremenu", @"menu:inWindow:"),
                       CMD(@"options", @"options:inWindow:"),
                       CMD(@"ounmap", @"unmap:inWindow:"),
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
                       CMD(@"smap", @"map:inWindow:"),
                       CMD(@"smapclear", @"mapclear:inWindow:"),
                       CMD(@"smenu", @"menu:inWindow:"),
                       CMD(@"snext", @"next:inWindow:"),
                       CMD(@"sniff", @"sniff:inWindow:"),
                       CMD(@"snomagic", @"submagic:inWindow:"),
                       CMD(@"snoremap", @"map:inWindow:"),
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
                       CMD(@"sunmap", @"unmap:inWindow:"),
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
                       CMD(@"vmapclear", @"mapclear:inWindow:"),
                       CMD(@"vmenu", @"menu:inWindow:"),
                       CMD(@"vnoremap", @"map:inWindow:"),
                       CMD(@"vnew", @"splitview:inWindow:"),
                       CMD(@"vnoremenu", @"menu:inWindow:"),
                       CMD(@"vsplit", @"splitview:inWindow:"),
                       CMD(@"vunmap", @"unmap:inWindow:"),
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
                       CMD(@"xhelp", @"xhelp:inWindow:"), // Quick Help (XVim Original)
                       CMD(@"xit", @"exit:inWindow:"),
                       CMD(@"xall", @"wqall:inWindow:"),
                       CMD(@"xmap", @"map:inWindow:"),
                       CMD(@"xmapclear", @"mapclear:inWindow:"),
                       CMD(@"xmenu", @"menu:inWindow:"),
                       CMD(@"xnoremap", @"map:inWindow:"),
                       CMD(@"xnoremenu", @"menu:inWindow:"),
                       CMD(@"xunmap", @"unmap:inWindow:"),
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

- (void)dealloc{
    [_excommands release];
    [super dealloc];
}

// This method correnspons parsing part of get_address in ex_cmds.c
- (NSUInteger)getAddress:(unichar*)parsing :(unichar**)cmdLeft inWindow:(XVimWindow*)window
{
    XVimSourceView* view = [window sourceView];
    //DVTFoldingTextStorage* storage = [view textStorage];
    //TRACE_LOG(@"Storage Class:%@", NSStringFromClass([storage class]));
    NSUInteger addr = NSNotFound;
    NSUInteger begin = [view selectedRange].location;
    NSUInteger end = [view selectedRange].location + [view selectedRange].length-1;
    unichar* tmp;
    NSUInteger count;
    unichar mark;
    
    // Parse base addr (line number)
    switch (*parsing)
    {
        case '.':
            parsing++;
            addr = [view lineNumber:begin];
            break;
        case '$':			    /* '$' - last line */
            parsing++;
            addr = [view numberOfLines];
            break;
        case '\'':
            // XVim does support only '< '> marks for visual mode
            mark = parsing[1];
            if( '<' == mark ){
                addr = [view lineNumber:begin];
                parsing+=2;
            }else if( '>' == mark ){
                addr = [view lineNumber:end];
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
            addr = [[NSString stringWithCharacters:tmp length:count] unsignedIntValue];
            if( 0 == addr ){
                addr = NSNotFound;
            }
    }
    
    // Parse additional modifier for addr ( ex. $-10 means 10 line above from end of file. Parse '-10' part here )
    for (;;)
    {
        // Skip whitespaces
        while( isWhiteSpace(*parsing) ){
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
            n = [[NSString stringWithCharacters:tmp length:count] unsignedIntValue];
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
    XVimExArg* exarg = [[[XVimExArg alloc] init] autorelease]; 
    NSUInteger len = [cmd length];
    
    // Create unichar array to parse. Its easier
    NSMutableData* dataCmd = [NSMutableData dataWithLength:(len+1)*sizeof(unichar)];
    unichar* pCmd = (unichar*)[dataCmd bytes];
    [cmd getCharacters:pCmd range:NSMakeRange(0,len)];
    pCmd[len] = 0; // NULL terminate
     
    unichar* parsing = pCmd;
    
    // 1. skip comment lines and leading space ( XVim does not handling commnet lines )
    for( NSUInteger i = 0; i < len && ( isWhiteSpace(*parsing) || *parsing == ':' ); i++,parsing++ );
    
    // 2. handle command modifiers
    // XVim does not support command mofifiers at the moment
    
    // 3. parse range
    exarg.lineBegin = NSNotFound;
    exarg.lineEnd = NSNotFound;
	
    XVimSourceView* view = [window sourceView];
    for(;;){
        NSUInteger addr = [self getAddress:parsing :&parsing inWindow:window];
        if( NSNotFound == addr ){
            if( *parsing == '%' ){ // XVim only supports %
                exarg.lineBegin = 1;
                exarg.lineEnd = [view numberOfLines];
                parsing++;
            }
        }else{
            exarg.lineEnd = addr;
        }
        
        if( exarg.lineBegin == NSNotFound ){ // If its first range 
            exarg.lineBegin = exarg.lineEnd;
        }
        
        if( *parsing != ',' ){
            break;
        }
        
        parsing++;
    }
    
    if( exarg.lineBegin == NSNotFound ){
        // No range expression found. Use current line as range
        exarg.lineBegin = [view lineNumber:[view selectedRange].location];
        exarg.lineEnd =  exarg.lineBegin;
    }
    
    // 4. parse command
    // In window command and its argument must be separeted by space
    unichar* tmp = parsing;
    NSUInteger count = 0;
    while( isAlpha(*parsing) || *parsing == '!' ){
        parsing++;
        count++;
    }

    if( 0 != count ){
        exarg.cmd = [NSString stringWithCharacters:tmp length:count];
    }else{
        // no command
        exarg.cmd = nil;
    }
    
    while( isWhiteSpace(*parsing)  ){
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
          
    // Actual parsing is done in following method.
    XVimExArg* exarg = [self parseCommand:cmd inWindow:window];
    if( exarg.cmd == nil ) {
		XVimSourceView* srcView = [window sourceView];
		
        // Jump to location
        NSUInteger pos = [srcView positionAtLineNumber:exarg.lineBegin column:0];
        if( NSNotFound == pos ){
            pos = [srcView positionAtLineNumber:[srcView numberOfLines] column:0];
        }
        NSUInteger pos_wo_space = [srcView nextNonBlankInALine:pos];
        if( NSNotFound == pos_wo_space ){
            pos_wo_space = pos;
        }
        [srcView setSelectedRange:NSMakeRange(pos_wo_space,0)];
        [srcView scrollTo:[window insertionPoint]];
        return;
    }
    
    // switch on command name
    for( XVimExCmdname* cmdname in _excommands ){
        if( [cmdname.cmdName hasPrefix:[exarg cmd]] ){
            SEL method = NSSelectorFromString(cmdname.methodName);
            if( [self respondsToSelector:method] ){
                [self performSelector:method withObject:exarg withObject:window];
                break;
            }
        }
    }
    
    return;
}

///////////////////
//   Commands    //
///////////////////
- (void)commit:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(commitCommand:) to:nil from:self];
}

- (void)sub:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	XVimSearch *searcher = [[XVim instance] searcher];
    [searcher substitute:args.arg from:args.lineBegin to:args.lineEnd inWindow:window];
}

- (void)set:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    NSString* setCommand = [args.arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    XVimSourceView* srcView = [window sourceView];
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
        [srcView setWrapsLines:YES];
    }
    else if( [setCommand isEqualToString:@"nowrap"] ){
        [srcView setWrapsLines:NO];
    }                
}

- (void)write:(XVimExArg*)args inWindow:(XVimWindow*)window
{ // :w
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
}

- (void)exit:(XVimExArg*)args inWindow:(XVimWindow*)window
{ // :wq
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
    [NSApp sendAction:@selector(closeDocument:) to:nil from:self];
}

- (void)quit:(XVimExArg*)args inWindow:(XVimWindow*)window
{ // :q
    [NSApp sendAction:@selector(closeDocument:) to:nil from:self];
}

/*
- (void)debugMenu:(NSMenu*)menu :(int)depth{
    NSMutableString* tabs = [[[NSMutableString alloc] init] autorelease];
    for( int i = 0 ; i < depth; i++ ){
        [tabs appendString:@"\t"];
    }
    for(NSMenuItem* item in [menu itemArray] ){
        if( ![item isSeparatorItem]  ){
            TRACE_LOG(@"%@Title:%@    Action:%@", tabs, [item title], NSStringFromSelector([item action]));
        }
        [self debugMenu:[item submenu] :depth+1];
    }
}
 */
- (void)debug:(XVimExArg*)args inWindow:(XVimWindow*)window
{
}

- (void)reg:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    TRACE_LOG(@"registers: %@", [[XVim instance] registers])
}

- (void)make:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"b" charactersIgnoringModifiers:@"b" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

- (void)mapMode:(int)mode withArgs:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	NSString *argString = args.arg;
	NSScanner *scanner = [NSScanner scannerWithString:argString];
	
	NSMutableArray *subStrings = [[NSMutableArray alloc] init];
	NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
	for (;;)
	{
		NSString *string;
		[scanner scanCharactersFromSet:ws intoString:&string];
		
		if (scanner.isAtEnd) { break; }
		[scanner scanUpToCharactersFromSet:ws intoString:&string];
		
		[subStrings addObject:string];
	}
  
	if (subStrings.count >= 2)
	{
		NSString *fromString = [subStrings objectAtIndex:0];
    
    [subStrings removeObjectAtIndex:0];
		NSString *toString = [subStrings componentsJoinedByString:@" "]; // get all args seperate by space
		
		NSMutableArray *fromKeyStrokes = [[NSMutableArray alloc] init];
		[XVimKeyStroke fromString:fromString to:fromKeyStrokes];
		
		NSMutableArray *toKeyStrokes = [[NSMutableArray alloc] init];
		[XVimKeyStroke fromString:toString to:toKeyStrokes];
		
		if (fromKeyStrokes.count > 0 && toKeyStrokes.count > 0)
		{
			XVimKeymap *keymap = [[XVim instance] keymapForMode:mode];
			[keymap mapKeyStroke:fromKeyStrokes to:toKeyStrokes];
		}
	}
}

- (void)map:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	[self mapMode:MODE_GLOBAL_MAP withArgs:args inWindow:window];
	[self mapMode:MODE_NORMAL withArgs:args inWindow:window];
	[self mapMode:MODE_OPERATOR_PENDING withArgs:args inWindow:window];
	[self mapMode:MODE_VISUAL withArgs:args inWindow:window];
}

- (void)nmap:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	[self mapMode:MODE_NORMAL withArgs:args inWindow:window];
}

- (void)vmap:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	[self mapMode:MODE_VISUAL withArgs:args inWindow:window];
}

- (void)omap:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	[self mapMode:MODE_OPERATOR_PENDING withArgs:args inWindow:window];
}

- (void)imap:(XVimExArg*)args inWindow:(XVimWindow*)window
{
	[self mapMode:MODE_INSERT withArgs:args inWindow:window];
}

- (void)run:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"r" charactersIgnoringModifiers:@"r" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

- (void)tabnext:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    [NSApp sendAction:@selector(selectNextTab:) to:nil from:self];
}

- (void)tabprevious:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    [NSApp sendAction:@selector(selectPreviousTab:) to:nil from:self];
}

- (void)tabclose:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    [NSApp sendAction:@selector(closeCurrentTab:) to:nil from:self];
}

- (void)nissue:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(jumpToNextIssue:) to:nil from:self];
}

- (void)pissue:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [NSApp sendAction:@selector(jumpToPreviousIssue:) to:nil from:self];
}

- (void)ncounterpart:(XVimExArg*)args inWindow:(XVimWindow*)window{
    // To make forcus proper
    // We must make forcus back to editor first then invoke the command.
    // This is because I do not know how to move focus on newly visible text editor by invoking this command.
    // Without this focus manipulation the focus after the command does not goes to the text editor
    [window setForcusBackToSourceView];
    [NSApp sendAction:@selector(jumpToNextCounterpart:) to:nil from:self];
}

- (void)pcounterpart:(XVimExArg*)args inWindow:(XVimWindow*)window{
    [window setForcusBackToSourceView];
    [NSApp sendAction:@selector(jumpToPreviousCounterpart:) to:nil from:self];
}

- (void)xhelp:(XVimExArg*)args inWindow:(XVimWindow*)window
{
    [NSApp sendAction:@selector(showQuickHelp:) to:nil from:self];
}

- (void)xccmd:(XVimExArg*)args inWindow:(XVimWindow*)window{
    SEL sel = NSSelectorFromString([[args arg] stringByAppendingString:@":"]);
    [window setForcusBackToSourceView];
    [NSApp sendAction:sel  to:nil from:self];
}

- (void)sort:(XVimExArg *)args inWindow:(XVimWindow *)window
{
    XVimSourceView *view = [window sourceView];
	NSRange range = NSMakeRange([args lineBegin], [args lineEnd] - [args lineBegin] + 1);
    
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
    
    [view sortLinesInRange:range withOptions:options];
}

@end
