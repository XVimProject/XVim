# Feature List

We try to keep this up to date, but sometimes implementation can get ahead of
documentation. If a command is missing, just try it in XVim first - it might
already be there!

If you've tried a command and it really is missing, feel free to create an issue and a
friendly contributor will pick it up eventually.

## Motion
b, B, f, F, gg, G, h, j, k, l, w, W, t, T, 0, $, ^, %, +, -, {, }, (, ), n, N, ', `, M, H, L

Comma and semicolon are supported. Toggle inclusive/exclusive by v is supported.

## Mark

File-local and Global marks are supported.

The '^' mark (last insertion point) and '.' mark (last change point) are also supported.
gi (insert mode at last insertion point) is supported.

Known issue: When deleteing a line before a mark the mark position should go up along with the line marked but currently XVim does not follow the line. It stays at the absolution position as it was marked.

## Scroll

C-d, C-f, C-e, C-u, C-b, C-y, zz, zb, zt

## Jumps
C-o, C-i, gd

If you want to open the file under the cursor you can use 'gd' instead of 'gf' in XVim environment.

## Insert
a, A, i, I, o, O

You can use Ctrl-o to enter to temparary normal mode during insert mode.

Ctrl-w,Ctrl-y,Ctrl-e commands in insert mode are suppported. If you want to use Ctrl-e as "move to end of line" in insert mode (which is default Xcode behaviour),
you can specify following line in .xvimrc.

     inoremap <C-e> <C-o>$
      

## Yank, put and change

d, dd(d_), D, y, yy(y_), Y, c, cc(c_), C, r, s, S, x, X

## Line join

J

## Shift block

Normal mode: >, >>, <, <<

## Case change operations

Normal mode: ~, gu, gU, g~

Visual mode: u, U, ~, gu, gU

## Undo

u, C-r

## Visual
v, V, Ctrl-v

(v, V in visual mode to toggle or escape from visual mode is supported)

Inserting with visual block is not supported currently (Ctrl-v + Shift-I does not work.)

## Operation in Visual

## Window manipulation

 Input     | Operation
-----------|---------------------------
  C-w n    | Add new assistant (Use layout of the last)
  C-w q    | Delete one assistant editor
  C-w s    | Add new assistant editor. Assistant editors are laid out holizontally.
  C-w v    | Add new assistant editor. Assistant editors are laid out vertically.
C-w h,j,k,l| Move focus between editors

The behaviour of window manipulations is slitely different from Vim's one. This is becuase that Xcode doesn't have a concept of multiple equivalent text views in a window.
Instead, Xcode has a concept of a main editor and assistant editors. A main editor always stays in a window and you can add/remove multiple assistant editors.
You can NOT split a main editor but just can add assistant editors.
All the manipulations XVim does is add/split assistant editors.
The layout is forced to change with Ctrl-w,s or Ctrl-w,v .

## Search and Replace

/, ?, #, \*, g*, g#, :s, n, N

Regex search is supported using the [ICU regex](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSRegularExpression_Class/Reference/Reference.html) format.

Substitution does not work as Vim does. When you input command following

    :%s/xxxx/yyyy/

XVim does replace the first occurence of xxxx IN THE FILE (not each line ).
If you want to replace all the occurence of xxxx with yyyy in the file you can specify

    :%s/xxxx/yyyy/g
    
Currently replacing first occurence of xxxx with yyyy each line is not available

## Insert mode commands

C-y, C-e

## Print status commands

C-g

## Text Object

ib, iB, i(, i), i{, i}, i[, i], i>, i<, i", i', iw, iW
ab, aB, a(, a), a{, a}, a[, a], a>, a<, a", a', aw, aW

## Recording

q, @

## Dot command

The dot command ('.') is supported.

## Ex commands

 Command   | Note
-----------|-----
  :w[rite] | 
  :wq      | 
  :q[uit]  |
  :register| Show contents of registers
  :s[ubstitute]|
  :set     | See Options for supported variables
  :map     | Show all the current mapping. When with arguments maps globally across XVim, in all modes
  :nmap    | Maps normal mode
  :vmap    | Maps visual mode
  :imap    | Maps insert mode
  :omap    | Maps operator pending mode

## XVim original commands

 Command   | Note
-----------|-----
  :run     | Invoke Xcode's 'run' command
  :make    | Invoke Xcode's 'build' command
  :xhelp   | Show quick help for current insertion point
  :xccmd   | Invoke arbitrary command in Xcode's actions in its menu. Takes one argument as its action to invoke. Actions [here](https://github.com/JugglerShu/XVim/blob/master/Documents/Developers/MenuActionList.txt) are available.
  :nissue  | Invoke "jump to next issue". ":ni" does the same.
  :pissue  | Invoke "jump to previous issue". ":pi" does the same.
  :ncounterpart | Invoke "jump to next counterpart". ":nc" does the same.
  :pcounterpart | Invoke "jump to previous counterpart". ":pc" does the same.

## Options

 Command       | Note
---------------|-----
  [no]ignorecase |
  [no]wrap |
  [no]wrapscan |
  [no]errorbells |
  [no]incsearch |
  [no]gdefault |
  [no]smartcase |
  [no]number |
  [no]hlsearch |
  guioptions | See below
  timeoutlen | The time in milliseconds that is waited for mapped key sequence to complete (default 1000)
  laststatus | 0 or 1 : status line is hidden, 2 : status line is displayed  (default 2)
  clipboard | ":set clipboard=unnamed" to share system clipboard with unnamed register
  [no]vimregex | Tells XVim to use Vim's regular expression. Currently support \<,\> for word boundary, \c,\C for specifying case (in)sensitiveness.


## guioptions

A limited subset of Vim options is implemented.

Option | Effect
-------|--------
r | Show vertical scrollbar
b | Show horizontal scrollbar

These changes only take effect on startup, meaning this option is only effective if used from within your .xvimrc.

## Key mapping

XVim supports five map commands: map, nmap, vmap, imap, omap.
A map command can change one or more keystrokes into one or more key strokes.

Note: The default timeout value for multi-key mapping completion is 1 seconds (1000 milliseconds). You can change it using 'timeoutlen' option.

Examples: 

    nmap n e
    imap ' <Esc>
    nmap u 5jiInsert some text<Esc>
    nmap ,w :w<cr>


## .xvimrc

At startup XVim looks for ~/.xvimrc. Each line in this file is executed 
as an ex command. This allows you to configure mappings and options.

Example:

    set ignorecase
    set wrapscan
    set guioptions=r
    nmap n e

## Known problems
 See XVim issue page.


## Experimental

### :xctabctrl (Ex command)
:xctabctrl command takes one argument and send message to the current tab workspace window.
A tab workspace window handles a lot of usuful actions provided by Xcode.
For example following command shows/hides a utility area (right side of a window)

      :xctabctrl showUtilitiesArea:
      :xctabctrl hideUtilitiesArea:

The arguments :xctabctrl accepts are method names in IDEWorkspaceTabController class.
See IDEKit.h file in XVim source code and find the class.
It has a lot of  actions (selectors) which takes one argument. These are the methods
we can call directly through the ex command.
Some does work well but some does not. Try using it to find out if it works as you like.
If you once find some usuful feature in it you can map it to key input via :map command.

(Note that the argument for :xctabctrl always ends with ":" as shown above)
