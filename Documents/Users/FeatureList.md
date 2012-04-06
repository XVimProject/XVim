# Feature List

Some commands here do not behave as original Vim or just lack its ability.
For example, 'gg' moves a cursor to the begining of document but currently '3gg'
also behaves same as 'gg' where it should moves a cursor to 3rd line.
It is just lack of implemntation. 

If you feel unconfortable with some commands
wait for the implemenation patiently or let me know through the XVim issue page.

The index of the list below corresponds to the help document of Vim.

## Motion

 Key | Note
-----|-----
 b   | 
 B   | 
 f   |
 F   | 
 g   | Currently only supports 'gg' to go to the 1st line.
 G   |
 h,j,k,l | 
 w   |
 W   | 
 0,$ | 
 ^   | 
 %   |  
 +,- |
 {,} |
 (,) |
 n,N | 
 '',` | Move to the marked position. 'm' is supporeted to make a mark 

Numeric argument is supported.


## Scroll

 Key | Note
-----|-----
 C-d | Currently works same as C-f (page down) 
 C-f |  
 C-u | Currently works same as C-b (page up) 
 C-b | 

Numeric argument is supported.


## Insert

 Key | Note
-----|-----
 a,A |
 i,I |

Numeric argument is supported.


## Change

 Key | Note
-----|-----
 d,dd,D |
 y,yy |
 c    |
 r    |
 x,X  |
 J    |
 >,>> |
 <,<< |


Numeric argument is supported.


## Undo

 Key | Note
-----|-----
 u   |
 C-r |

Numeric argument is supported.

## Visual

 Key | Note
-----|-----
 v,V |

Ctrl-v is not supported now.

The navigation is Visual Mode is not works greatly. Still in construction...

## Search and Replace

 Key | Note
-----|-----
 /,? | 

Currently replace is not supported.

Regex is supporeted in search command but it is ICU regex and not Vim''s one.


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

