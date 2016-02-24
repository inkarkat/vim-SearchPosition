" Test foo match range reporting within visible lines.

let g:SearchPosition_MatchRangeShowRelativeThreshold = 'visible'

" Create a defined height of 20 for the test source file.
new
wincmd w
20wincmd _
call vimtest#SkipAndQuitIf(winheight(0) != 20, 'Cannot create a window with a height of exactly 20')

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
