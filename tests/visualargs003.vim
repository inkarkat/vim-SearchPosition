" Test single newline argument matches in visual mode. 

set selection=exclusive
execute "normal! gg/^$/\<CR>"
execute "normal vj\<A-m>"

call vimtest#Quit()

