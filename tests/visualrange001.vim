" Test foo matches at various visual selections in buffer.

execute "normal ggVG\<A-n>"
call TriggerSearchElsewhere()
execute "normal ggV15G\<A-n>"

" Test that the cursor position is always at the top of the selection, regards
" of how the selection is done.
call TriggerSearchElsewhere()
execute "normal 15GVgg\<A-n>"
call TriggerSearchElsewhere()
execute "normal ggV15Go\<A-n>"

call TriggerSearchElsewhere()
execute "normal 70GV76G\<A-n>"

call vimtest#Quit()
