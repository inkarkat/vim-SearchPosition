" Test no foo matches at various visual selections in buffer. 

execute "normal 7GV11G\<A-n>"

execute "silent! normal! /\\<does-not-exist\\>/\<CR>"
execute "normal ggVG\<A-n>"

call vimtest#Quit()

