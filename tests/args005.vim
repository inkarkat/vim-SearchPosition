" Test no matches and special positions.

echo 'No match for doesNotMatch'
SearchPosition /doesNotMatch/

echo 'Match after this line and further'
normal! 11G0
SearchPosition /\n\n/

echo 'Match in empty line'
normal! j
SearchPosition /\n\n/

echomsg 'No match in first, empty line'
normal! ggO
SearchPosition /doesNotMatch/

call vimtest#Quit()
