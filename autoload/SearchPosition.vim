" SearchPosition.vim: Show relation to search pattern matches in range or buffer. 
"
" DEPENDENCIES:
"   - ingosearch.vim autoload script. 
"   - EchoWithoutScrolling.vim autoload script (optional, only for showing
"     pattern). 
"
" Copyright: (C) 2008-2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.12.003	08-Oct-2010	Using SearchPosition#SavePosition() instead of
"				(Vim version-dependent) mark to keep the cursor
"				at the position where the operator was invoked
"				(only necessary with a backward {motion}). 
"				BUG: Incorrect reporting of sole match in folded
"				line when the current line is empty and the
"				pattern starts matching a newline character.
"				The reason is that search() doesn't match a
"				pattern that starts with a newline character on
"				an empty line. We have to move to the last
"				character on the line before the empty line to
"				achieve the match. 
"   1.11.002	02-Jun-2010	Appended "; total N" to evaluations that
"				excluded the match on the cursor from the
"				"overall" count, as it was misleading what
"				"overall" meant in this context. 
"   1.10.001	08-Jan-2010	Moved functions from plugin to separate autoload
"				script.
"				file creation
let s:save_cpo = &cpo
set cpo&vim

function! s:GetMatchesCnt( range, pattern )
    let l:matchesCnt = 0

    redir => l:matches
    try
	silent execute 'keepjumps' a:range . 's/' . escape(a:pattern, '/') . '//gn'
	redir END
	let l:matchesCnt = matchstr( l:matches, '\n\zs\d\+' )
    catch /^Vim\%((\a\+)\)\=:E486/ " Pattern not found
    finally
	redir END
    endtry

    return l:matchesCnt
endfunction
" The position in the key is a boolean (0/1) whether there are any matches. 
" The placeholder {N} will be filled with the actual number, where N is: 
" 1: matches before line, 2: matches current line, 3: matches after line,
" 4: before cursor, 5: exact on cursor, 6: after cursor in current line
"
" Terminology: 
" "overall" is used when all matches are limited to a certain partition of the
" range, e.g. all before the cursor (and thus none on or after the cursor). 
" "total" is used when there's no such partition; matches are scattered
" throughout the range. 
" Example: 
"6 = /4
"   2 | 1
"     2/ = 3
"   2 matches before and 1 after cursor in this line, 6 and 3 overall; total 9
let s:evaluation = {
\   '000000': 'No matches', 
\   '001000': '{3} matches after this line', 
\   '010000': '{2} matches in this fold', 
\   '010001': '{6} matches after cursor in this line', 
\   '010010': 'On sole match', 
\   '010011': 'On first match, {6} after cursor in this line', 
\   '010100': '{4} matches before cursor in this line', 
\   '010101': '{4} matches before and {6} after cursor in this line; total {2}', 
\   '010110': 'On last match, {4} before cursor in this line', 
\   '010111': 'On match, {4} before and {6} after cursor in this line; total {2}', 
\   '011000': '{2} matches in this fold, {3} following; total {2+3}', 
\   '011001': '{6} matches after cursor in this line, {3+6} overall', 
\   '011010': 'On sole match in this line, {3} in following lines', 
\   '011011': 'On first match, {6} following in line, {3+6} overall; total {2+3}', 
\   '011100': '{4} matches before cursor in this line, {3} in following lines; total {2+3}', 
\   '011101': '{4} matches before and {6} after cursor in this line, {3} in following lines; total {2+3}', 
\   '011110': 'On last match of {4+5} in this line, {3} in following lines; total {2+3}', 
\   '011111': 'On match, {4+5+6} in this line, {3} in following lines; total {2+3}', 
\   '100000': '{1} matches before this line', 
\   '101000': '{1} matches before and {3} after this line; total {1+3}', 
\   '110000': '{2} matches in this fold, {1} before; total {1+2}', 
\   '110001': '{6} matches after cursor in this line, {1} in previous lines; total {1+2}', 
\   '110010': 'On sole match in this line, {1} in previous lines', 
\   '110011': 'On first match of {5+6} in this line, {1} in previous lines; total {1+2}', 
\   '110100': '{4} matches before cursor in this line, {1+4} overall', 
\   '110101': '{4} matches before and {6} after cursor in this line, {1} in previous lines; total {1+2}', 
\   '110110': 'On last match, {4} previous in line, {1+4} overall; total {1+2}', 
\   '110111': 'On match, {4+5+6} in this line, {1} in previous lines; total {1+2}', 
\   '111000': '{2} matches in this fold, {1} before, {3} following; total {1+2+3}', 
\   '111001': '{6} matches after cursor in this line, {3+6} following, {1} in previous lines; total {1+2+3}', 
\   '111010': 'On sole match in this line, {1} before and {3} after this line; total {1+2+3}', 
\   '111011': 'On first match of {5+6} in this line, {1} before and {3+6} following; total {1+2+3}', 
\   '111100': '{4} matches before cursor in this line, {1+4} before overall, {3} after this line; total {1+2+3}', 
\   '111101': '{4} matches before and {6} after cursor in this line, {1+4} and {3+6} overall; total {1+2+3}', 
\   '111110': 'On last match of {4+5} in this line, {1+4} before, {3} in following lines; total {1+2+3}', 
\   '111111': 'On match, {4+5+6} in this line, {1+4} before, {3+6} following; total {1+2+3}', 
\}
function! s:ResolveParameters( matchResults, placeholder )
    let l:result = 0
    for l:parameter in split( matchstr( a:placeholder, '^{\zs.*\ze}$' ), '+' )
	let l:result += a:matchResults[ l:parameter - 1 ]
    endfor
    return l:result
endfunction
function! s:Evaluate( matchResults )
    let l:matchVector = join( map( copy(a:matchResults), '!!v:val' ), '' )

    if ! has_key(s:evaluation, l:matchVector)
	return [0, 'Special atoms have distorted the tally']
    endif

    let l:evaluation = s:evaluation[ l:matchVector ]
    let l:evaluation = substitute( l:evaluation, '{\%(\d\|+\)\+}', '\=s:ResolveParameters(a:matchResults, submatch(0))', 'g' )
    return [1, substitute( l:evaluation, '1 matches' , '1 match', 'g' )]
endfunction
function! s:Report( line1, line2, pattern, evaluation )
    let [l:isSuccessful, l:evaluationText] = a:evaluation

    redraw  " This is necessary because of the :redir done earlier. 
    echo ''

    let l:range = ''
    if g:SearchPosition_ShowRange && l:isSuccessful
	let l:range = a:line1 . ',' . a:line2
	if a:line1 == 1 && a:line2 == line('$')
	    let l:range = ''
	elseif a:line1 == a:line2
	    let l:range = a:line1
	endif
	if ! empty(l:range)
	    let l:range = ':' . l:range . ' '
	    echon l:range 
	endif
    endif

    let l:pattern = ''
    if g:SearchPosition_ShowPattern
	let l:pattern = EchoWithoutScrolling#TranslateLineBreaks('/' . (empty(a:pattern) ? @/ : escape(a:pattern, '/')) . '/')
    endif

    execute 'echohl' (l:isSuccessful ? 
    \	empty(g:SearchPosition_HighlightGroup) ? 'None' : g:SearchPosition_HighlightGroup :
    \	'WarningMsg'
    \)
    echon l:evaluationText
    if l:isSuccessful | echohl None | endif

    if ! empty(l:pattern)
	" Assumption: The evaluation message only contains printable ASCII
	" characters; we can thus simple use strlen() to determine the number of
	" occupied virtual columns. Otherwise,
	" EchoWithoutScrolling#DetermineVirtColNum() could be used. 
	echon EchoWithoutScrolling#Truncate( ' for ' . l:pattern, (strlen(l:range) + strlen(l:evaluationText)) )
    endif
    if ! l:isSuccessful | echohl None | endif
endfunction
function! SearchPosition#SearchPosition( line1, line2, pattern, isLiteral )
    let l:startLine = (a:line1 ? max([a:line1, 1]) : 1)
    let l:endLine = (a:line2 ? min([a:line2, line('$')]) : line('$'))
    " If the end of range is in a closed fold, Vim processes all lines inside
    " the fold, even when '.' or a fixed line number has been specified. We
    " correct the end line merely for output cosmetics, as the calculation is
    " not affected by this. 
    let l:endLine = (foldclosed(l:endLine) == -1 ? l:endLine : foldclosedend(l:endLine))
"****D echomsg '****' a:line1 a:line2
"****D echomsg '****' l:startLine l:endLine

    " Skip processing if there is no pattern. 
    if empty(a:pattern) && (a:isLiteral || empty(@/))
	" Using an empty pattern would cause the previously used search pattern
	" to be used (if there is any). 
	echohl ErrorMsg
	let v:errmsg = (a:isLiteral ? 'Nothing selected' : 'E35: No previous regular expression')
	echomsg v:errmsg
	echohl None
	return
    endif

    let l:save_cursor = getpos('.')
    let l:cursorLine = line('.')
    let l:cursorVirtCol = virtcol('.')
    let l:isCursorOnClosedFold = (foldclosed(l:cursorLine) != -1)
    let l:isCursorInsideRange = (l:cursorLine >= l:startLine && l:cursorLine <= l:endLine)

    " This triple records matches relative to the current line or current closed
    " fold. 
    let l:matchesBefore = 0
    let l:matchesCurrent = 0
    let l:matchesAfter = 0

    if l:cursorLine >= l:startLine
	let l:lineBeforeCurrent = (l:isCursorInsideRange ? 
	\   (l:isCursorOnClosedFold ? foldclosed(l:cursorLine) : l:cursorLine) - 1 :
	\   l:endLine
	\)
	if l:lineBeforeCurrent >= l:startLine
	    let l:matchesBefore = s:GetMatchesCnt( l:startLine . ',' . l:lineBeforeCurrent, a:pattern )
	endif
    endif

    if l:isCursorInsideRange
	" The range '.' represents either the current line or the entire current
	" closed fold. 
	" We're not interested in matches on the current line if it's outside
	" the range to be examined. 
	let l:matchesCurrent = s:GetMatchesCnt('.', a:pattern)
    endif

    if l:cursorLine <= l:endLine
	let l:lineAfterCurrent = (l:isCursorInsideRange ?
	\   (l:isCursorOnClosedFold ? foldclosedend(l:cursorLine) : l:cursorLine) + 1 :
	\   l:startLine
	\)
	if l:lineAfterCurrent <= l:endLine
	    let l:matchesAfter = s:GetMatchesCnt( l:lineAfterCurrent . ',' . l:endLine, a:pattern )
	endif
    endif
"****D echomsg '****' l:matchesBefore '/' l:matchesCurrent '/' l:matchesAfter

    let l:before = 0
    let l:exact = 0
    let l:after = 0
    if ! l:isCursorOnClosedFold && l:isCursorInsideRange
	" We're not interested in matches on the current line if we're on a
	" closed fold; this would be just too much information. The user can
	" quickly open the fold and re-run the command if he's interested. 
	" We're also not interested if the current line is outside the passed
	" range. 
	call cursor(l:cursorLine, 1)
	" This triple records matches only in the current line (not current fold!),
	" split into before, on, and after cursor position. 
	while search( a:pattern, (l:before + l:exact + l:after ? '' : 'c'), l:cursorLine )
	    let l:matchVirtCol = virtcol('.')
	    if l:matchVirtCol < l:cursorVirtCol
		let l:before += 1
	    elseif l:matchVirtCol == l:cursorVirtCol
		let l:exact += 1
	    elseif l:matchVirtCol > l:cursorVirtCol
		let l:after += 1
	    else
		throw 'ASSERT: false'
	    endif 
	endwhile

	" search() doesn't match a pattern that starts with a newline character
	" on an empty line. We have to move to the last character on the line
	" before the empty line to achieve the match. 
	"
	" Detect this special case when the current line is empty and there were
	" no matches. Without this special handling, SearchPosition would deduce
	" that the current line is inside a fold. 
	if empty(getline(l:cursorLine)) && (l:before + l:exact + l:after) == 0
	    " Moving to the previous character must be handled differently when
	    " on the first line; in that case, we need wrap-around enabled. 
	    let [l:adaptionMovement, l:searchFlags, l:searchStopLine] =
	    \	(l:cursorLine == 1 ?
	    \	    ['G$', 'w', 0] :
	    \	    ['k$', 'c', l:cursorLine]
	    \	)
	    execute 'normal!' l:adaptionMovement
	    if search(a:pattern, l:searchFlags, l:searchStopLine)
		" On an empty line, the cursor is usually on the newline
		" character, but it can be after it (= match before cursor) if
		" 'virtualedit' is set. 
		if l:cursorVirtCol == 1
		    let l:exact += 1
		else
		    let l:before += 1
		endif
	    endif
	endif

	call setpos('.', l:save_cursor)
"****D echomsg '****' l:before '/' l:exact '/' l:after
    endif

    call s:Report( l:startLine, l:endLine, a:pattern, s:Evaluate( [l:matchesBefore, l:matchesCurrent, l:matchesAfter, l:before, l:exact, l:after] ) )
endfunction

function! SearchPosition#SavePosition()
    let s:savePositionBeforeOperator = getpos('.')
endfunction
function! SearchPosition#Operator( type )
    " After the custom operator, the cursor will be positioned at the beginning
    " of the range, so if the motion goes backward, the cursor will move. For
    " this report-only command this is not desired, so we use the saved position
    " to pin the cursor down. 
    if getpos('.') != s:savePositionBeforeOperator
	call setpos('.', s:savePositionBeforeOperator)
    endif
    unlet s:savePositionBeforeOperator

    call SearchPosition#SearchPosition(line("'["), line("']"), '', 0)
endfunction

let s:pattern = ''
function! SearchPosition#SetCword( isWholeWord )
    let l:cword = expand('<cword>')
    if ! empty(l:cword)
	let s:pattern = ingosearch#LiteralTextToSearchPattern(l:cword, a:isWholeWord, '')
    endif
    return s:pattern
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
