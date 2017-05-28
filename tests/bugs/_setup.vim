call vimtest#AddDependency('vim-ingo-library')

runtime plugin/SearchPosition.vim

" Increase the default width, so that messages aren't truncated.
if &columns < 120
    set columns=120
endif
