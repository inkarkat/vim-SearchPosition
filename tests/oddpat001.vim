" Test odd patterns.

echo 'Assumes fold because no match inside line:'
SearchPosition /\%#foo/
normal! 0
SearchPosition /\%#foo/
normal! $
SearchPosition /\%#foo/

normal! 0
echo 'Matching inside line starts at first column:'
SearchPosition /\%#<foo/
normal! $
echo 'Match before cursor but no overall match in line:'
call ingo#err#Set('This should not appear')
SearchPosition /\%#<foo/
echo 'This is after the command'

call vimtest#Quit()
