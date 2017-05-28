" Test foo matches at various cursor positions in buffer. 

edit bug001.txt
normal! gg0
execute "normal! /\\<limitations\\>/\<CR>"
SearchPosition
normal! l
SearchPosition
normal! gg0
SearchPosition

call vimtest#Quit()
