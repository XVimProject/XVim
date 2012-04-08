# Feature List

Feature list here is not complete list but main features XVim is supporting.

So some commands not listed here may already be implemented.

If you feel unconfortable with some commands
wait for the implemenation patiently or let me know through the XVim issue page.

The index of the list below corresponds to the help document of Vim.

## Motion
b,B,f,F,g,G,h,j,k,l,w,W,0,$,^,%,+,-,{,},(,),n,N,',`

Motion with mark is supported.
Numeric argument is supported.
Toggle Inclusive/Exclusive by v is supported

## Scroll

C-d,C-f,C-u,C-b

Numeric argument is supported.


## Insert
a,A,i,I

Numeric argument is supported.


## Change

d,dd,D,y,yy,c,r,x,X,J,>,>>,<,<<

Numeric argument is supported.


## Undo

u,C-r

Numeric argument is supported.

## Visual
v,V

Ctrl-v is not supported now.
(v,V in visual mode to toggle or escape from visual mode is supported)

The navigation is Visual Mode is not works greatly. Still in construction...

## Search and Replace

/,?,:s

Regex is supporeted in search command but it is ICU regex and not Vim''s one.
':s' is partially supported.

## Text Object

ib, iB, i(, i), i{, i}, i[, i], i>, i<, i", i', iw, iW
ab, aB, a(, a), a{, a}, a[, a], a>, a<, a", a', aw, aW

## Recording

q,@

Repeat command by '.' is also supported

## Cmdline

 Command   | Note
-----------|-----
  :w[rite] | 
  :wq      | 
  :q[uit]  |
  :debug   |
  :run     | This is XVim original command to invoke XCodes 'run' command
  :make    | This is XVim original command to invoke XCodes 'build' command
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

# Know problems
 See XVim issue page.

