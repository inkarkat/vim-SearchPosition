runtime plugin/SearchPosition.vim

" Increase the default width, so that messages aren't truncated. 
if &columns < 120
    set columns=120
endif

edit test.txt
normal! gg0
execute "normal! /\\<foo\\>/\<CR>"

