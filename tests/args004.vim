" Test argument starting with newline matches. 

SearchPosition \nT
normal! 12G0
SearchPosition \nT

normal! 13G$
SearchPosition \nT

set virtualedit=all
normal! 13G$l
SearchPosition \nT

echomsg 'Test in first, empty line'
normal! ggO
SearchPosition \nT

call vimtest#Quit()

