" Test foo match range reporting.

SearchPosition
10 | SearchPosition
70 | SearchPosition
$  | SearchPosition

73 | SearchPosition Galasaseray
82 | SearchPosition Galasaseray

10 | SearchPosition /^/

81,88SearchPosition /^"/

21 | SearchPosition line

21 | SearchPosition /on/

call vimtest#Quit()
