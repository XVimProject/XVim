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

Numeric arugment is supported.


## Scroll

 Key | Note
-----|-----
 C-d | Currently works same as C-f (page down) 
 C-f |  
 C-u | Currently works same as C-b (page up) 
 C-b | 

Numeric arugment is supported.


## Insert

 Key | Note
-----|-----
 a,A |
 i,I |

Numeric arugment is supported.


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


Numeric arugment is supported.


## Undo

 Key | Note
-----|-----
 u   |
 C-r |

Numeric arugment is supported.

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

 Command | Note
---------|-----
  :w     | 
  :wq    | 
  :run   | This is XVim original command to invoke XCodes 'run' command
  :make  | This is XVim original command to invoke XCodes 'build' command


## Options

 Command       | Note
---------------|-----
  [no]ignorecase |
  [no]wrap |
  [no]wrapscan |
  [no]errorbells |
    

# Know problems
 See XVim issue page.

