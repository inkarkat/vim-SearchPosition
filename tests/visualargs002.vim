" Test special argument matches in visual mode. 
" Tests visual selection spanning multiple lines. 

execute "normal! /la\\nle/\<CR>"

set selection=exclusive
execute "normal vj\<A-m>"
execute "normal vj$\<A-m>"

set selection=inclusive
execute "normal vj\<A-m>"
execute "normal vj$\<A-m>"

call vimtest#Quit()

