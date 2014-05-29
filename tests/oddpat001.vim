" Test odd patterns. 

echo 'Assumes fold because no match inside line: '
SearchPosition \%#foo
normal! 0
SearchPosition \%#foo
normal! $
SearchPosition \%#foo

normal! 0
echo 'Matching inside line starts at first column: '
SearchPosition \%#<foo
normal! $
echo 'Match before cursor but no overall match in line: '
SearchPosition \%#<foo

call vimtest#Quit()

