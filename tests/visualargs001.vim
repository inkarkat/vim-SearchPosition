" Test argument matches in visual mode.

execute "normal! /tool/\<CR>"
execute "normal ve\<A-m>"
execute "normal! 2/one line/\<CR>"
execute "normal v2e\<A-m>"
call setline('$', '\([''"]\)one\s\+line\1')
execute "normal G0v$\<A-m>"

call vimtest#Quit()
