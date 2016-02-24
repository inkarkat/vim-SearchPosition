" Test foo matches at various ranges in buffer. 

.SearchPosition
1,15SearchPosition
normal! $
1,15SearchPosition
normal! 16G0
1,15SearchPosition
70,76SearchPosition
normal! G$
70,76SearchPosition
normal! N
70,76SearchPosition

call vimtest#Quit()

