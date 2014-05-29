" Test single newline argument matches. 

SearchPosition \n
normal! $
execute "normal! gg/^$/\<CR>"
SearchPosition \n

set virtualedit=all
echomsg 'Test after empty line'
normal! l
SearchPosition \n


echomsg 'Test before EOL'
normal! gg$
SearchPosition \n
echomsg 'Test on EOL'
normal! $l
SearchPosition \n
echomsg 'Test after EOL'
normal! $2l
SearchPosition \n

echomsg 'Test in first, empty line'
normal! ggO
SearchPosition \n

call vimtest#Quit()

