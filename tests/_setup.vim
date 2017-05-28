runtime plugin/SearchPosition.vim

" Increase the default width, so that messages aren't truncated.
if &columns < 120
    set columns=120
endif

" Don't use relative ranges for the visible lines by default, as Vim's window
" height is undetermined.
let g:SearchPosition_MatchRangeShowRelativeThreshold = 9

function! TriggerSearchElsewhere()
    execute 'normal' (line('.') == 1 ? 'G' : 'gg') . "\<A-n>\<C-o>"
endfunction
function! TriggerCwordElsewhere()
    execute 'normal' (line('.') == 1 ? 'G' : 'gg') . "\<A-m>\<C-o>"
endfunction

edit test.txt
execute "normal! gg0/\\<foo\\>/\<CR>"
