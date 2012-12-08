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

File-local marks are supported. Global marks are not yet supported.

The '.' mark (last insertion point) is supported.
gi (insert mode at last insertion point) is supported.

## Scroll

C-d, C-f, C-e, C-u, C-b, C-y, zz, zb, zt

## Jumps
C-o, C-i, gd

If you want to open the file under the cursor you can use 'gd' instead of 'gf' in XVim environment.

## Insert
a, A, i, I, o, O

## Yank, put and change

d, dd, D, y, yy, Y, c, cc, C, r, s, x, X

## Line join

J

## Shift block

Normal mode: >, >>, <, <<

Visual mode: >, <

## Case change operations

Normal mode: ~, gu, gU, g~

Visual mode: u, U, ~, gu, gU

## Undo

u, C-r

## Visual
v, V

Ctrl-v is not supported now.
(v, V in visual mode to toggle or escape from visual mode is supported)

Visual block mode is currently not supported.

## Search and Replace

/, ?, #, \*, g*, g#, :s, n, N

Regex search is supported using the ICU regex format.

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
  :s[ubstitute]|
  :set     | See Options for supported variables
  :map     | Maps globally across XVim, in all modes
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
  :nissue  | Invoke "jump to next issue". ":ni" does the samse.
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
  guioptions | See below
  timeoutlen | The time in milliseconds that is waited for mapped key sequence to complete (default 1000)

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

# Known problems
 See XVim issue page.

