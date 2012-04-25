# Feature List

We try to keep this up to date, but sometimes implementation can get ahead of
documentation. If a command is missing, just try it in XVim first - it might
already be there!

If you've tried it and it's actually missing, feel free to create an issue and a
friendly contributor will pick it up eventually.

## Motion
b, B, f, F, gg, G, h, j, k, l, w, W, t, T, 0, $, ^, %, +, -, {, }, (, ), n, N, ', `, M, H, L

Comma and semicolon are supported
Toggle inclusive/exclusive by v is supported

## Mark

File-local marks are supported.
Global marks are not yet supported.

## Scroll

C-d, C-f, C-u, C-b, zz, zb, zt

## Jumps
C-o, C-i

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

/, ?, #, *, g*, g#, :s, n, N

Regex search is supported using the ICU regex format.

## Text Object

ib, iB, i(, i), i{, i}, i[, i], i>, i<, i", i', iw, iW
ab, aB, a(, a), a{, a}, a[, a], a>, a<, a", a', aw, aW

## Recording

q, @

## Dot command

The dot command ('.') is supported

## Ex commands

 Command   | Note
-----------|-----
  :w[rite] | 
  :wq      | 
  :q[uit]  |
  :debug   |
  :run     | This is XVim original command to invoke Xcodes 'run' command
  :make    | This is XVim original command to invoke Xcodes 'build' command
  :s[ubstitute]|
  :set     | See Options for supported variables
  :map     | Maps globally across XVim, in all modes
  :nmap    | Maps normal mode
  :vmap    | Maps visual mode
  :imap    | Maps insert mode
  :omap    | Maps operator pending mode


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


## Key mapping

XVim supports five map commands: map, nmap, vmap, imap, omap.
A map command can change any one keystroke into one or more key strokes.

Examples: 

    nmap n e
    imap ' <Esc>
    nmap u 5jiInsert some text<Esc>


## .xvimrc

At startup XVim looks for ~/.xvimrc. Each line in this file is executed 
as an ex command. This allows you to configure mappings and options.

Example:

    set ignorecase
    set wrapscan
    nmap n e

# Known problems
 See XVim issue page.

