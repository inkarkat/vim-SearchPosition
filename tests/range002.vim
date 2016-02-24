" Test no foo matches at various ranges in buffer. 

normal! 2G0

.SearchPosition
7,11SearchPosition
normal! G$
7,11SearchPosition
normal! 7G0
7,11SearchPosition

execute "silent! normal! /\\<does-not-exist\\>/\<CR>"
SearchPosition
.SearchPosition

call vimtest#Quit()

