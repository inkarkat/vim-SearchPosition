" Test foo matches at various cursor positions in buffer. 

runtime plugin/SearchPosition.vim

" Increase the default width, so that messages aren't truncated. 
if &columns < 120
    set columns=120
endif

edit bug001.txt
normal! gg0
execute "normal! /\\<limitations\\>/\<CR>"
SearchPosition
normal! l
SearchPosition
normal! gg0
SearchPosition

call vimtest#Quit()

