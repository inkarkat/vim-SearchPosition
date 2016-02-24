" Test foo matches at various cursor positions in buffer. 

SearchPosition
normal! n
SearchPosition
normal! h
SearchPosition
normal! ll
SearchPosition
normal! n
SearchPosition
normal! 0
SearchPosition
normal! $
SearchPosition
normal! G$
SearchPosition

call vimtest#Quit()

