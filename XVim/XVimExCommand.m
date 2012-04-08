//
//  XVimExCommand.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerSHu.Net. All rights reserved.
//

#import "XVim.h"
#import "DVTSourceTextView.h"
#import "XVimExCommand.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"

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
-(id)initWithXVim:(XVim*)xvim{
    if( self = [super init] ){
        // This is the ex command list.
        // This is list from ex_cmds.h in Vim source code.
        // The method names correspond the Vim's function name.
        // You can change the method name as needed ( Since Vim's one is not always suitable )
        
        _excommands = [[NSArray alloc] initWithObjects:
                       CMD(@"append", @"append:"),
                       CMD(@"abbreviate", @"abbreviate:"),
                       CMD(@"abclear", @"abclear:"),
                       CMD(@"aboveleft", @"wrongmodifier:"),
                       CMD(@"all", @"all:"),
                       CMD(@"amenu", @"menu:"),
                       CMD(@"anoremenu", @"menu:"),
                       CMD(@"args", @"args:"),
                       CMD(@"argadd", @"argadd:"),
                       CMD(@"argdelete", @"argdelete:"),
                       CMD(@"argdo", @"listdo:"),
                       CMD(@"argedit", @"argedit:"),
                       CMD(@"argglobal", @"args:"),
                       CMD(@"arglocal", @"args:"),
                       CMD(@"argument", @"argument:"),
                       CMD(@"ascii", @"ascii:"),
                       CMD(@"autocmd", @"autocmd:"),
                       CMD(@"augroup", @"autocmd:"),
                       CMD(@"aunmenu", @"menu:"),
                       CMD(@"buffer", @"buffer:"),
                       CMD(@"bNext", @"bprevious:"),
                       CMD(@"ball", @"buffer_all:"),
                       CMD(@"badd", @"edit:"),
                       CMD(@"bdelete", @"bunload:"),
                       CMD(@"behave", @"behave:"),
                       CMD(@"belowright", @"wrongmodifier:"),
                       CMD(@"bfirst", @"brewind:"),
                       CMD(@"blast", @"blast:"),
                       CMD(@"bmodified", @"bmodified:"),
                       CMD(@"bnext", @"bnext:"),
                       CMD(@"botright", @"wrongmodifier:"),
                       CMD(@"bprevious", @"bprevious:"),
                       CMD(@"brewind", @"brewind:"),
                       CMD(@"break", @"break:"),
                       CMD(@"breakadd", @"breakadd:"),
                       CMD(@"breakdel", @"breakdel:"),
                       CMD(@"breaklist", @"breaklist:"),
                       CMD(@"browse", @"wrongmodifier:"),
                       CMD(@"buffers", @"buflist_list:"),
                       CMD(@"bufdo", @"listdo:"),
                       CMD(@"bunload", @"bunload:"),
                       CMD(@"bwipeout", @"bunload:"),
                       CMD(@"change", @"change:"),
                       CMD(@"cNext", @"cnext:"),
                       CMD(@"cNfile", @"cnext:"),
                       CMD(@"cabbrev", @"abbreviate:"),
                       CMD(@"cabclear", @"abclear:"),
                       CMD(@"caddbuffer", @"cbuffer:"),
                       CMD(@"caddexpr", @"cexpr:"),
                       CMD(@"caddfile", @"cfile:"),
                       CMD(@"call", @"call:"),
                       CMD(@"catch", @"catch:"),
                       CMD(@"cbuffer", @"cbuffer:"),
                       CMD(@"cc", @"cc:"),
                       CMD(@"cclose", @"cclose:"),
                       CMD(@"cd", @"cd:"),
                       CMD(@"center", @"align:"),
                       CMD(@"cexpr", @"cexpr:"),
                       CMD(@"cfile", @"cfile:"),
                       CMD(@"cfirst", @"cc:"),
                       CMD(@"cgetfile", @"cfile:"),
                       CMD(@"cgetbuffer", @"cbuffer:"),
                       CMD(@"cgetexpr", @"cexpr:"),
                       CMD(@"chdir", @"cd:"),
                       CMD(@"changes", @"changes:"),
                       CMD(@"checkpath", @"checkpath:"),
                       CMD(@"checktime", @"checktime:"),
                       CMD(@"clist", @"qf_list:"),
                       CMD(@"clast", @"cc:"),
                       CMD(@"close", @"close:"),
                       CMD(@"cmap", @"map:"),
                       CMD(@"cmapclear", @"mapclear:"),
                       CMD(@"cmenu", @"menu:"),
                       CMD(@"cnext", @"cnext:"),
                       CMD(@"cnewer", @"qf_age:"),
                       CMD(@"cnfile", @"cnext:"),
                       CMD(@"cnoremap", @"map:"),
                       CMD(@"cnoreabbrev", @"abbreviate:"),
                       CMD(@"cnoremenu", @"menu:"),
                       CMD(@"copy", @"copymove:"),
                       CMD(@"colder", @"qf_age:"),
                       CMD(@"colorscheme", @"colorscheme:"),
                       CMD(@"command", @"command:"),
                       CMD(@"comclear", @"comclear:"),
                       CMD(@"compiler", @"compiler:"),
                       CMD(@"continue", @"continue:"),
                       CMD(@"confirm", @"wrongmodifier:"),
                       CMD(@"copen", @"copen:"),
                       CMD(@"cprevious", @"cnext:"),
                       CMD(@"cpfile", @"cnext:"),
                       CMD(@"cquit", @"cquit:"),
                       CMD(@"crewind", @"cc:"),
                       CMD(@"cscope", @"cscope:"),
                       CMD(@"cstag", @"cstag:"),
                       CMD(@"cunmap", @"unmap:"),
                       CMD(@"cunabbrev", @"abbreviate:"),
                       CMD(@"cunmenu", @"menu:"),
                       CMD(@"cwindow", @"cwindow:"),
                       CMD(@"delete", @"operators:"),
                       CMD(@"delmarks", @"delmarks:"),
                       CMD(@"debug", @"debug:"),
                       CMD(@"debuggreedy", @"debuggreedy:"),
                       CMD(@"delcommand", @"delcommand:"),
                       CMD(@"delfunction", @"delfunction:"),
                       CMD(@"display", @"display:"),
                       CMD(@"diffupdate", @"diffupdate:"),
                       CMD(@"diffget", @"diffgetput:"),
                       CMD(@"diffoff", @"diffoff:"),
                       CMD(@"diffpatch", @"diffpatch:"),
                       CMD(@"diffput", @"diffgetput:"),
                       CMD(@"diffsplit", @"diffsplit:"),
                       CMD(@"diffthis", @"diffthis:"),
                       CMD(@"digraphs", @"digraphs:"),
                       CMD(@"djump", @"findpat:"),
                       CMD(@"dlist", @"findpat:"),
                       CMD(@"doautocmd", @"doautocmd:"),
                       CMD(@"doautoall", @"doautoall:"),
                       CMD(@"drop", @"drop:"),
                       CMD(@"dsearch", @"findpat:"),
                       CMD(@"dsplit", @"findpat:"),
                       CMD(@"edit", @"edit:"),
                       CMD(@"earlier", @"later:"),
                       CMD(@"echo", @"echo:"),
                       CMD(@"echoerr", @"execute:"),
                       CMD(@"echohl", @"echohl:"),
                       CMD(@"echomsg", @"execute:"),
                       CMD(@"echon", @"echo:"),
                       CMD(@"else", @"else:"),
                       CMD(@"elseif", @"else:"),
                       CMD(@"emenu", @"emenu:"),
                       CMD(@"endif", @"endif:"),
                       CMD(@"endfunction", @"endfunction:"),
                       CMD(@"endfor", @"endwhile:"),
                       CMD(@"endtry", @"endtry:"),
                       CMD(@"endwhile", @"endwhile:"),
                       CMD(@"enew", @"edit:"),
                       CMD(@"ex", @"edit:"),
                       CMD(@"execute", @"execute:"),
                       CMD(@"exit", @"exit:"),
                       CMD(@"exusage", @"exusage:"),
                       CMD(@"file", @"file:"),
                       CMD(@"files", @"buflist_list:"),
                       CMD(@"filetype", @"filetype:"),
                       CMD(@"find", @"find:"),
                       CMD(@"finally", @"finally:"),
                       CMD(@"finish", @"finish:"),
                       CMD(@"first", @"rewind:"),
                       CMD(@"fixdel", @"fixdel:"),
                       CMD(@"fold", @"fold:"),
                       CMD(@"foldclose", @"foldopen:"),
                       CMD(@"folddoopen", @"folddo:"),
                       CMD(@"folddoclosed", @"folddo:"),
                       CMD(@"foldopen", @"foldopen:"),
                       CMD(@"for", @"while:"),
                       CMD(@"function", @"function:"),
                       CMD(@"global", @"global:"),
                       CMD(@"goto", @"goto:"),
                       CMD(@"grep", @"make:"),
                       CMD(@"grepadd", @"make:"),
                       CMD(@"gui", @"gui:"),
                       CMD(@"gvim", @"gui:"),
                       CMD(@"help", @"help:"),
                       CMD(@"helpfind", @"helpfind:"),
                       CMD(@"helpgrep", @"helpgrep:"),
                       CMD(@"helptags", @"helptags:"),
                       CMD(@"hardcopy", @"hardcopy:"),
                       CMD(@"highlight", @"highlight:"),
                       CMD(@"hide", @"hide:"),
                       CMD(@"history", @"history:"),
                       CMD(@"insert", @"append:"),
                       CMD(@"iabbrev", @"abbreviate:"),
                       CMD(@"iabclear", @"abclear:"),
                       CMD(@"if", @"if:"),
                       CMD(@"ijump", @"findpat:"),
                       CMD(@"ilist", @"findpat:"),
                       CMD(@"imap", @"imap:"),
                       CMD(@"imapclear", @"mapclear:"),
                       CMD(@"imenu", @"menu:"),
                       CMD(@"inoremap", @"map:"),
                       CMD(@"inoreabbrev", @"abbreviate:"),
                       CMD(@"inoremenu", @"menu:"),
                       CMD(@"intro", @"intro:"),
                       CMD(@"isearch", @"findpat:"),
                       CMD(@"isplit", @"findpat:"),
                       CMD(@"iunmap", @"unmap:"),
                       CMD(@"iunabbrev", @"abbreviate:"),
                       CMD(@"iunmenu", @"menu:"),
                       CMD(@"join", @"join:"),
                       CMD(@"jumps", @"jumps:"),
                       CMD(@"k", @"mark:"),
                       CMD(@"keepmarks", @"wrongmodifier:"),
                       CMD(@"keepjumps", @"wrongmodifier:"),
                       CMD(@"keepalt", @"wrongmodifier:"),
                       CMD(@"list", @"print:"),
                       CMD(@"lNext", @"cnext:"),
                       CMD(@"lNfile", @"cnext:"),
                       CMD(@"last", @"last:"),
                       CMD(@"language", @"language:"),
                       CMD(@"laddexpr", @"cexpr:"),
                       CMD(@"laddbuffer", @"cbuffer:"),
                       CMD(@"laddfile", @"cfile:"),
                       CMD(@"later", @"later:"),
                       CMD(@"lbuffer", @"cbuffer:"),
                       CMD(@"lcd", @"cd:"),
                       CMD(@"lchdir", @"cd:"),
                       CMD(@"lclose", @"cclose:"),
                       CMD(@"lcscope", @"cscope:"),
                       CMD(@"left", @"align:"),
                       CMD(@"leftabove", @"wrongmodifier:"),
                       CMD(@"let", @"let:"),
                       CMD(@"lexpr", @"cexpr:"),
                       CMD(@"lfile", @"cfile:"),
                       CMD(@"lfirst", @"cc:"),
                       CMD(@"lgetfile", @"cfile:"),
                       CMD(@"lgetbuffer", @"cbuffer:"),
                       CMD(@"lgetexpr", @"cexpr:"),
                       CMD(@"lgrep", @"make:"),
                       CMD(@"lgrepadd", @"make:"),
                       CMD(@"lhelpgrep", @"helpgrep:"),
                       CMD(@"ll", @"cc:"),
                       CMD(@"llast", @"cc:"),
                       CMD(@"llist", @"qf_list:"),
                       CMD(@"lmap", @"map:"),
                       CMD(@"lmapclear", @"mapclear:"),
                       CMD(@"lmake", @"make:"),
                       CMD(@"lnoremap", @"map:"),
                       CMD(@"lnext", @"cnext:"),
                       CMD(@"lnewer", @"qf_age:"),
                       CMD(@"lnfile", @"cnext:"),
                       CMD(@"loadview", @"loadview:"),
                       CMD(@"loadkeymap", @"loadkeymap:"),
                       CMD(@"lockmarks", @"wrongmodifier:"),
                       CMD(@"lockvar", @"lockvar:"),
                       CMD(@"lolder", @"qf_age:"),
                       CMD(@"lopen", @"copen:"),
                       CMD(@"lprevious", @"cnext:"),
                       CMD(@"lpfile", @"cnext:"),
                       CMD(@"lrewind", @"cc:"),
                       CMD(@"ltag", @"tag:"),
                       CMD(@"lunmap", @"unmap:"),
                       CMD(@"lvimgrep", @"vimgrep:"),
                       CMD(@"lvimgrepadd", @"vimgrep:"),
                       CMD(@"lwindow", @"cwindow:"),
                       CMD(@"ls", @"	buflist_list:"),
                       CMD(@"move", @"copymove:"),
                       CMD(@"mark", @"mark:"),
                       CMD(@"make", @"make:"),
                       CMD(@"map", @"map:"),
                       CMD(@"mapclear", @"mapclear:"),
                       CMD(@"marks", @"marks:"),
                       CMD(@"match", @"match:"),
                       CMD(@"menu", @"menu:"),
                       CMD(@"menutranslate", @"menutranslate:"),
                       CMD(@"messages", @"messages:"),
                       CMD(@"mkexrc", @"mkrc:"),
                       CMD(@"mksession", @"mkrc:"),
                       CMD(@"mkspell", @"mkspell:"),
                       CMD(@"mkvimrc", @"mkrc:"),
                       CMD(@"mkview", @"mkrc:"),
                       CMD(@"mode", @"mode:"),
                       CMD(@"mzscheme", @"mzscheme:"),
                       CMD(@"mzfile", @"mzfile:"),
                       CMD(@"next", @"next:"),
                       CMD(@"nbkey", @"nbkey:"),
                       CMD(@"new", @"splitview:"),
                       CMD(@"nmap", @"nmap:"),
                       CMD(@"nmapclear", @"mapclear:"),
                       CMD(@"nmenu", @"menu:"),
                       CMD(@"nnoremap", @"map:"),
                       CMD(@"nnoremenu", @"menu:"),
                       CMD(@"noremap", @"map:"),
                       CMD(@"noautocmd", @"wrongmodifier:"),
                       CMD(@"nohlsearch", @"nohlsearch:"),
                       CMD(@"noreabbrev", @"abbreviate:"),
                       CMD(@"noremenu", @"menu:"),
                       CMD(@"normal", @"normal:"),
                       CMD(@"number", @"print:"),
                       CMD(@"nunmap", @"unmap:"),
                       CMD(@"nunmenu", @"menu:"),
                       CMD(@"open", @"open:"),
                       CMD(@"oldfiles", @"oldfiles:"),
                       CMD(@"omap", @"omap:"),
                       CMD(@"omapclear", @"mapclear:"),
                       CMD(@"omenu", @"menu:"),
                       CMD(@"only", @"only:"),
                       CMD(@"onoremap", @"map:"),
                       CMD(@"onoremenu", @"menu:"),
                       CMD(@"options", @"options:"),
                       CMD(@"ounmap", @"unmap:"),
                       CMD(@"ounmenu", @"menu:"),
                       CMD(@"print", @"print:"),
                       CMD(@"pclose", @"pclose:"),
                       CMD(@"perl", @"perl:"),
                       CMD(@"perldo", @"perldo:"),
                       CMD(@"pedit", @"pedit:"),
                       CMD(@"pop", @"tag:"),
                       CMD(@"popup", @"popup:"),
                       CMD(@"ppop", @"ptag:"),
                       CMD(@"preserve", @"preserve:"),
                       CMD(@"previous", @"previous:"),
                       CMD(@"promptfind", @"gui_mch_find_dialog:"),
                       CMD(@"promptrepl", @"gui_mch_replace_dialog:"),
                       CMD(@"profile", @"profile:"),
                       CMD(@"profdel", @"breakdel:"),
                       CMD(@"psearch", @"psearch:"),
                       CMD(@"ptag", @"ptag:"),
                       CMD(@"ptNext", @"ptag:"),
                       CMD(@"ptfirst", @"ptag:"),
                       CMD(@"ptjump", @"ptag:"),
                       CMD(@"ptlast", @"ptag:"),
                       CMD(@"ptnext", @"ptag:"),
                       CMD(@"ptprevious", @"ptag:"),
                       CMD(@"ptrewind", @"ptag:"),
                       CMD(@"ptselect", @"ptag:"),
                       CMD(@"put", @"put:"),
                       CMD(@"pwd", @"pwd:"),
                       CMD(@"python", @"python:"),
                       CMD(@"pyfile", @"pyfile:"),
                       CMD(@"quit", @"quit:"),
                       CMD(@"quitall", @"quit_all:"),
                       CMD(@"qall", @"quit_all:"),
                       CMD(@"read", @"read:"),
                       CMD(@"recover", @"recover:"),
                       CMD(@"redo", @"redo:"),
                       CMD(@"redir", @"redir:"),
                       CMD(@"redraw", @"redraw:"),
                       CMD(@"redrawstatus", @"redrawstatus:"),
                       CMD(@"registers", @"reg:"),
                       CMD(@"resize", @"resize:"),
                       CMD(@"retab", @"retab:"),
                       CMD(@"return", @"return:"),
                       CMD(@"rewind", @"rewind:"),
                       CMD(@"right", @"align:"),
                       CMD(@"rightbelow", @"wrongmodifier:"),
                       CMD(@"run",@"run:"), // This is XVim original command
                       CMD(@"runtime", @"runtime:"),
                       CMD(@"ruby", @"ruby:"),
                       CMD(@"rubydo", @"rubydo:"),
                       CMD(@"rubyfile", @"rubyfile:"),
                       CMD(@"rviminfo", @"viminfo:"),
                       CMD(@"substitute", @"sub:"),
                       CMD(@"sNext", @"previous:"),
                       CMD(@"sargument", @"argument:"),
                       CMD(@"sall", @"all:"),
                       CMD(@"sandbox", @"wrongmodifier:"),
                       CMD(@"saveas", @"write:"),
                       CMD(@"sbuffer", @"buffer:"),
                       CMD(@"sbNext", @"bprevious:"),
                       CMD(@"sball", @"buffer_all:"),
                       CMD(@"sbfirst", @"brewind:"),
                       CMD(@"sblast", @"blast:"),
                       CMD(@"sbmodified", @"bmodified:"),
                       CMD(@"sbnext", @"bnext:"),
                       CMD(@"sbprevious", @"bprevious:"),
                       CMD(@"sbrewind", @"brewind:"),
                       CMD(@"scriptnames", @"scriptnames:"),
                       CMD(@"scriptencoding", @"scriptencoding:"),
                       CMD(@"scscope", @"scscope:"),
                       CMD(@"set", @"set:"),
                       CMD(@"setfiletype", @"setfiletype:"),
                       CMD(@"setglobal", @"set:"),
                       CMD(@"setlocal", @"set:"),
                       CMD(@"sfind", @"splitview:"),
                       CMD(@"sfirst", @"rewind:"),
                       CMD(@"shell", @"shell:"),
                       CMD(@"simalt", @"simalt:"),
                       CMD(@"sign", @"sign:"),
                       CMD(@"silent", @"wrongmodifier:"),
                       CMD(@"sleep", @"sleep:"),
                       CMD(@"slast", @"last:"),
                       CMD(@"smagic", @"submagic:"),
                       CMD(@"smap", @"map:"),
                       CMD(@"smapclear", @"mapclear:"),
                       CMD(@"smenu", @"menu:"),
                       CMD(@"snext", @"next:"),
                       CMD(@"sniff", @"sniff:"),
                       CMD(@"snomagic", @"submagic:"),
                       CMD(@"snoremap", @"map:"),
                       CMD(@"snoremenu", @"menu:"),
                       CMD(@"source", @"source:"),
                       CMD(@"sort", @"sort:"),
                       CMD(@"split", @"splitview:"),
                       CMD(@"spellgood", @"spell:"),
                       CMD(@"spelldump", @"spelldump:"),
                       CMD(@"spellinfo", @"spellinfo:"),
                       CMD(@"spellrepall", @"spellrepall:"),
                       CMD(@"spellundo", @"spell:"),
                       CMD(@"spellwrong", @"spell:"),
                       CMD(@"sprevious", @"previous:"),
                       CMD(@"srewind", @"rewind:"),
                       CMD(@"stop", @"stop:"),
                       CMD(@"stag", @"stag:"),
                       CMD(@"startinsert", @"startinsert:"),
                       CMD(@"startgreplace", @"startinsert:"),
                       CMD(@"startreplace", @"startinsert:"),
                       CMD(@"stopinsert", @"stopinsert:"),
                       CMD(@"stjump", @"stag:"),
                       CMD(@"stselect", @"stag:"),
                       CMD(@"sunhide", @"buffer_all:"),
                       CMD(@"sunmap", @"unmap:"),
                       CMD(@"sunmenu", @"menu:"),
                       CMD(@"suspend", @"stop:"),
                       CMD(@"sview", @"splitview:"),
                       CMD(@"swapname", @"swapname:"),
                       CMD(@"syntax", @"syntax:"),
                       CMD(@"syncbind", @"syncbind:"),
                       CMD(@"t", @"copymove:"),
                       CMD(@"tNext", @"tag:"),
                       CMD(@"tag", @"tag:"),
                       CMD(@"tags", @"tags:"),
                       CMD(@"tab", @"wrongmodifier:"),
                       CMD(@"tabclose", @"tabclose:"),
                       CMD(@"tabdo", @"listdo:"),
                       CMD(@"tabedit", @"splitview:"),
                       CMD(@"tabfind", @"splitview:"),
                       CMD(@"tabfirst", @"tabnext:"),
                       CMD(@"tabmove", @"tabmove:"),
                       CMD(@"tablast", @"tabnext:"),
                       CMD(@"tabnext", @"tabnext:"),
                       CMD(@"tabnew", @"splitview:"),
                       CMD(@"tabonly", @"tabonly:"),
                       CMD(@"tabprevious", @"tabnext:"),
                       CMD(@"tabNext", @"tabnext:"),
                       CMD(@"tabrewind", @"tabnext:"),
                       CMD(@"tabs", @"tabs:"),
                       CMD(@"tcl", @"tcl:"),
                       CMD(@"tcldo", @"tcldo:"),
                       CMD(@"tclfile", @"tclfile:"),
                       CMD(@"tearoff", @"tearoff:"),
                       CMD(@"tfirst", @"tag:"),
                       CMD(@"throw", @"throw:"),
                       CMD(@"tjump", @"tag:"),
                       CMD(@"tlast", @"tag:"),
                       CMD(@"tmenu", @"menu:"),
                       CMD(@"tnext", @"tag:"),
                       CMD(@"topleft", @"wrongmodifier:"),
                       CMD(@"tprevious", @"tag:"),
                       CMD(@"trewind", @"tag:"),
                       CMD(@"try", @"try:"),
                       CMD(@"tselect", @"tag:"),
                       CMD(@"tunmenu", @"menu:"),
                       CMD(@"undo", @"undo:"),
                       CMD(@"undojoin", @"undojoin:"),
                       CMD(@"undolist", @"undolist:"),
                       CMD(@"unabbreviate", @"abbreviate:"),
                       CMD(@"unhide", @"buffer_all:"),
                       CMD(@"unlet", @"unlet:"),
                       CMD(@"unlockvar", @"lockvar:"),
                       CMD(@"unmap", @"unmap:"),
                       CMD(@"unmenu", @"menu:"),
                       CMD(@"unsilent", @"wrongmodifier:"),
                       CMD(@"update", @"update:"),
                       CMD(@"vglobal", @"global:"),
                       CMD(@"version", @"version:"),
                       CMD(@"verbose", @"wrongmodifier:"),
                       CMD(@"vertical", @"wrongmodifier:"),
                       CMD(@"visual", @"edit:"),
                       CMD(@"view", @"edit:"),
                       CMD(@"vimgrep", @"vimgrep:"),
                       CMD(@"vimgrepadd", @"vimgrep:"),
                       CMD(@"viusage", @"viusage:"),
                       CMD(@"vmap", @"vmap:"),
                       CMD(@"vmapclear", @"mapclear:"),
                       CMD(@"vmenu", @"menu:"),
                       CMD(@"vnoremap", @"map:"),
                       CMD(@"vnew", @"splitview:"),
                       CMD(@"vnoremenu", @"menu:"),
                       CMD(@"vsplit", @"splitview:"),
                       CMD(@"vunmap", @"unmap:"),
                       CMD(@"vunmenu", @"menu:"),
                       CMD(@"write", @"write:"),
                       CMD(@"wNext", @"wnext:"),
                       CMD(@"wall", @"wqall:"),
                       CMD(@"while", @"while:"),
                       CMD(@"winsize", @"winsize:"),
                       CMD(@"wincmd", @"wincmd:"),
                       CMD(@"windo", @"listdo:"),
                       CMD(@"winpos", @"winpos:"),
                       CMD(@"wnext", @"wnext:"),
                       CMD(@"wprevious", @"wnext:"),
                       CMD(@"wq", @"exit:"),
                       CMD(@"wqall", @"wqall:"),
                       CMD(@"wsverb", @"wsverb:"),
                       CMD(@"wviminfo", @"viminfo:"),
                       CMD(@"xit", @"exit:"),
                       CMD(@"xall", @"wqall:"),
                       CMD(@"xmap", @"map:"),
                       CMD(@"xmapclear", @"mapclear:"),
                       CMD(@"xmenu", @"menu:"),
                       CMD(@"xnoremap", @"map:"),
                       CMD(@"xnoremenu", @"menu:"),
                       CMD(@"xunmap", @"unmap:"),
                       CMD(@"xunmenu", @"menu:"),
                       CMD(@"yank", @"operators:"),
                       CMD(@"z", @"z:"),
                       CMD(@"!", @"bang:"),
                       CMD(@"#", @"print:"),
                       CMD(@"&", @"sub:"),
                       CMD(@"*", @"at:"),
                       CMD(@"<", @"operators:"),
                       CMD(@"=", @"equal:"),
                       CMD(@">", @"operators:"),
                       CMD(@"@", @"at:"),
                       CMD(@"Next", @"previous:"),
                       CMD(@"Print", @"print:"),
                       CMD(@"X", @"X:"),
                       CMD(@"~", @"sub:"),
                       
					   nil];
        _xvim = [xvim retain];
    }
    return self;
}

- (void)dealloc{
    [_excommands release];
    [_xvim release];
    [super dealloc];
}

// This method correnspons parsing part of get_address in ex_cmds.c
- (NSUInteger)getAddress:(unichar*)parsing :(unichar**)cmdLeft{
    DVTSourceTextView* view = [_xvim sourceView];
    DVTFoldingTextStorage* storage = [view textStorage];
    TRACE_LOG(@"Storage Class:%@", NSStringFromClass([storage class]));
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
            addr = [[NSString stringWithCharacters:tmp length:count] intValue];
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
            n = [[NSString stringWithCharacters:tmp length:count] intValue];
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

- (XVimExArg*)parseCommand:(NSString*)cmd{
    DVTSourceTextView* view = [_xvim sourceView];
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
    for(;;){
        NSUInteger addr = [self getAddress:parsing :&parsing];
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
    // In xvim command and its argument must be separeted by space
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
- (void)executeCommand:(NSString*)cmd{
    // cmd INCLUDE ":" character
    
    DVTSourceTextView* srcView = [_xvim sourceView];
    if( [cmd length] == 0 ){
        ERROR_LOG(@"command string empty");
        return;
    }
          
    // Actual parsing is done in following method.
    XVimExArg* exarg = [self parseCommand:cmd];
    if( exarg.cmd == nil ){
        // Jump to location
        NSUInteger pos = [srcView positionAtLineNumber:exarg.lineBegin column:0];
        NSUInteger pos_wo_space = [srcView nextNonBlankInALine:pos];
        if( NSNotFound == pos_wo_space ){
            pos_wo_space = pos;
        }
        [srcView setSelectedRange:NSMakeRange(pos_wo_space,0)];
        [srcView scrollToCursor];
        return;
    }
    
    // switch on command name
    for( XVimExCmdname* cmdname in _excommands ){
        if( [cmdname.cmdName hasPrefix:[exarg cmd]] ){
            SEL method = NSSelectorFromString(cmdname.methodName);
            if( [self respondsToSelector:method] ){
                [self performSelector:method withObject:exarg];
                break;
            }
        }
    }
    
    return;
}

///////////////////
//   Commands    //
///////////////////

- (void)sub:(XVimExArg*)args{
    [[_xvim searcher] substitute:args.arg from:args.lineBegin to:args.lineEnd];
}

- (void)set:(XVimExArg*)args{
    NSString* setCommand = [args.arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    DVTSourceTextView* srcView = [_xvim sourceView];
    
    if( [setCommand rangeOfString:@"="].location != NSNotFound ){
        // "set XXX=YYY" form
        
    }else if( [setCommand hasPrefix:@"no"] ){
        // "set noXXX" form
        NSString* prop = [setCommand substringFromIndex:2];
        [_xvim.options setOption:prop value:[NSNumber numberWithBool:NO]];
    }else{
        // "set XXX" form
        [_xvim.options setOption:setCommand value:[NSNumber numberWithBool:YES]];
    }
    
    if( [setCommand isEqualToString:@"wrap"] ){
        [srcView setWrapsLines:YES];
    }
    else if( [setCommand isEqualToString:@"nowrap"] ){
        [srcView setWrapsLines:NO];
    }                
}

- (void)write:(XVimExArg*)args{ // :w
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
}

- (void)exit:(XVimExArg*)args{ // :wq
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
    [NSApp terminate:self];
}

- (void)quit:(XVimExArg*)args{ // :q
    [NSApp terminate:self];
}

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
- (void)debug:(NSString*)args{
    // Write any debug code.
    [_xvim setStaticMessage:@"testmessage"];
    //NSMenu* menu = [NSApp mainMenu];
    //[self debugMenu:menu :0];
    //[[_xvim cmdLine] ask:@"teststring" owner:self handler:@selector(test:) option:ASKING_OPTION_NONE]; 
}

- (void)reg:(XVimExArg*)args{
    TRACE_LOG(@"registers: %@", [_xvim registers])
}

- (void)make:(XVimExArg*)args{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"b" charactersIgnoringModifiers:@"b" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

- (void)mapMode:(int)mode withArgs:(XVimExArg*)args {
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
		
	if (subStrings.count == 2)
	{
		NSString *fromString = [subStrings objectAtIndex:0];
		NSString *toString = [subStrings objectAtIndex:1];
		XVimKeyStroke *fromKeyStroke = [XVimKeyStroke fromString:fromString];
		
		NSMutableArray *toKeyStrokes = [[NSMutableArray alloc] init];
		[XVimKeyStroke fromString:toString to:toKeyStrokes];
		
		if (fromKeyStroke && toKeyStrokes.count > 0)
		{
			XVimKeymap *keymap = [_xvim keymapForMode:mode];
			[keymap mapKeyStroke:fromKeyStroke to:toKeyStrokes];
		}
	}
}

- (void)map:(XVimExArg*)args {
	[self mapMode:MODE_GLOBAL_MAP withArgs:args];
	[self mapMode:MODE_NORMAL withArgs:args];
	[self mapMode:MODE_OPERATOR_PENDING withArgs:args];
	[self mapMode:MODE_VISUAL withArgs:args];
}

- (void)nmap:(XVimExArg*)args {
	[self mapMode:MODE_NORMAL withArgs:args];
}

- (void)vmap:(XVimExArg*)args {
	[self mapMode:MODE_VISUAL withArgs:args];
}

- (void)omap:(XVimExArg*)args {
	[self mapMode:MODE_OPERATOR_PENDING withArgs:args];
}

- (void)imap:(XVimExArg*)args {
	[self mapMode:MODE_INSERT withArgs:args];
}

- (void)run:(XVimExArg*)args{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"r" charactersIgnoringModifiers:@"r" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

- (void)tabnext:(XVimExArg*)args{
    [NSApp sendAction:@selector(selectNextTab:) to:nil from:self];
}

- (void)tabprevious:(XVimExArg*)args{
    [NSApp sendAction:@selector(selectPreviousTab:) to:nil from:self];
}

- (void)tabclose:(XVimExArg*)args{
    [NSApp sendAction:@selector(closeCurrentTab:) to:nil from:self];
}

@end
