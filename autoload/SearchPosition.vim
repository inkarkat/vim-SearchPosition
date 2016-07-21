" SearchPosition.vim: Show relation to search pattern matches in range or buffer.
"
" DEPENDENCIES:
"   - ingo/avoidprompt.vim autoload script
"   - ingo/compat.vim autoload script
"   - ingo/range.vim autoload script
"   - ingo/regexp.vim autoload script
"   - ingo/window/dimensions.vim autoload script
"
" Copyright: (C) 2008-2015 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.30.015	15-Apr-2015	Tweak s:TranslateLocation() for line 1:  :2
"				looks better than :.+1 there.
"				Tweak s:TranslateLocation() for last line and
"				use :$-N instead of :.-N there.
"				Tweak s:TranslateLocation() to prefer absolute
"				numbers over offsets spanning more than half of
"				the entire buffer.
"				BUG: Incorrect de-pluralization of "11
"				match[es]".
"				Also store the results of
"				:SearchPositionMultiple in the message history.
"   1.30.014	14-Apr-2015	Extract s:EchoResult().
"				Add SearchPosition#SearchPositionMultiple() to
"				implement :SearchPositionMultiple command.
"   1.22.013	14-Apr-2015	Also submit the plugin's result message (in
"				unhighlighted form) to the message history (for
"				recall and comparison).
"				Refactoring: Extract s:GetReport() from
"				s:Report().
"				Refactoring: Extract s:SearchAndEvaluate() from
"				SearchPosition#SearchPosition().
"   1.22.012	16-Mar-2015	BUG: Also need to account for cursor within
"				closed fold for the start line number, not just
"				the end. Replace explicit adaptation with
"				ingo#range#NetStart() / ingo#range#NetEnd().
"   1.21.011	11-Feb-2015	FIX: After "Special atoms have distorted the
"				tally" warning, an additional stray (last
"				actual) error is repeated. s:Report() also needs
"				to return 1 after such warning.
"				BUG: "Special atoms have distorted the tally"
"				warning instead of "No matches" when on first
"				line. Must not allow previous matching line when
"				that is identical to 0, the return value of
"				search() when it fails.
"				BUG: "Special atoms have distorted the tally"
"				when doing :SearchPosition/\n\n/ on empty line.
"				The special case for \n matching is actually
"				more complex; need to also ensure that the match
"				doesn't lie completely on the previous line, and
"				retry without the "c" search flag if it does.
"   1.21.010	30-Jun-2014	ENH: Show relative range when the lines are
"				shown in the current window with a new default
"				configuration value of "visible" for
"				g:SearchPosition_MatchRangeShowRelativeThreshold.
"				Use separate
"				g:SearchPosition_MatchRangeShowRelativeEndThreshold
"				for threshold at the end.
"   1.20.009	30-May-2014	ENH: Also show range that the matches fall into;
"				locations close to the current line in relative form.
"   1.16.008	05-May-2014	Abort commands and mappings on error.
"				Use SearchPosition#OperatorExpr() to also handle
"				[count] before the operator mapping.
"   1.16.007	14-Jun-2013	Minor: Make substitute() robust against
"				'ignorecase'.
"   1.16.006	07-Jun-2013	Move EchoWithoutScrolling.vim into ingo-library.
"   1.16.005	24-May-2013	Move ingosearch.vim to ingo-library.
"   1.13.004	08-Oct-2010	BUG: The previous fix for the incorrect
"				reporting of sole match in folded line was
"				susceptible to non-local matches when current
"				line is the first line. Fixed by explicitly
"				checking resulting line number of search().
"				line when the current line is empty
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

function! s:RecordRange( range )
    let l:lnum = line('.')
    " Assumption: We're invoked with ascending line numbers.
    if a:range[1] == 0
	let a:range[0] = l:lnum
	let a:range[1] = l:lnum
    else
	let a:range[1] = l:lnum
    endif
endfunction
function! s:GetMatchesStats( range, pattern )
    let l:matchesCnt = 0
    let l:range = [0x7FFFFFFF, 0]

    redir => l:matches
    try
	silent execute 'keepjumps' a:range . 's/' . escape(a:pattern, '/') . '/\=s:RecordRange(l:range)/gn'
	redir END
	let l:matchesCnt = str2nr(matchstr( l:matches, '\n\zs\d\+' ))
    catch /^Vim\%((\a\+)\)\=:E486:/ " Pattern not found
    finally
	redir END
    endtry

    return [l:matchesCnt] + l:range
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
    let l:matchVector = join(map(copy(a:matchResults), '!!v:val'), '')

    if ! has_key(s:evaluation, l:matchVector)
	return [0, 'Special atoms have distorted the tally']
    endif

    let l:evaluation = s:evaluation[ l:matchVector ]
    let l:evaluation = substitute(l:evaluation, '{\%(\d\|+\)\+}', '\=s:ResolveParameters(a:matchResults, submatch(0))', 'g')
    return [1, substitute(l:evaluation, '\C^1 matches' , '1 match', 'g')]
endfunction
function! s:TranslateLocation( lnum, isShowAbsoluteNumberForCurrentLine, firstVisibleLnum, lastVisibleLnum )
    if a:lnum == line('.')
	return (a:isShowAbsoluteNumberForCurrentLine ? a:lnum : '.')
    elseif a:lnum == line('$')
	return '$'
    elseif a:lnum == 1
	return '1'
    elseif a:lnum >= a:firstVisibleLnum && a:lnum <= a:lastVisibleLnum
	if line('.') == 1
	    return a:lnum   " :2 looks better than :.+1
	endif

	let l:offset = a:lnum - line('.')
	if ingo#compat#abs(l:offset) > line('$') / 2
	    return a:lnum   " Prefer absolute numbers over offsets spanning more than half of the entire buffer.
	endif

	return (line('.') == line('$') ? '$' : '.') . (l:offset < 0 ? l:offset : '+' . l:offset)
    elseif line('$') - a:lnum <= g:SearchPosition_MatchRangeShowRelativeEndThreshold
	return '$-' . (line('$') - a:lnum)
    else
	return a:lnum
    endif
endfunction
function! s:EvaluateMatchRange( line1, line2, firstMatchLnum, lastMatchLnum )
    if a:firstMatchLnum == a:line1 && a:lastMatchLnum == a:line2
	return ' spanning the entire ' . (a:line1 == 1 && a:line2 == line('$') ? 'buffer' : 'range')
    endif

    let l:isFallsOnCurrentLine = (a:firstMatchLnum == line('.') || a:lastMatchLnum == line('.'))

    let [l:firstVisibleLnum, l:lastVisibleLnum] = (g:SearchPosition_MatchRangeShowRelativeThreshold ==# 'visible' ?
    \   ingo#window#dimensions#DisplayedLines() :
    \   [line('.') - g:SearchPosition_MatchRangeShowRelativeThreshold, line('.') + g:SearchPosition_MatchRangeShowRelativeThreshold]
    \)
    let l:firstLocation = s:TranslateLocation(a:firstMatchLnum, l:isFallsOnCurrentLine, l:firstVisibleLnum, l:lastVisibleLnum)
    if a:firstMatchLnum == a:lastMatchLnum
	return (a:firstMatchLnum == line('.') ? '' : printf(' at %s', l:firstLocation))
    endif
    let l:lastLocation = s:TranslateLocation(a:lastMatchLnum, l:isFallsOnCurrentLine, l:firstVisibleLnum, l:lastVisibleLnum)
    return printf(' within %s,%s', l:firstLocation, l:lastLocation)
endfunction
function! s:GetReport( line1, line2, pattern, firstMatchLnum, lastMatchLnum, evaluation )
    let [l:isSuccessful, l:evaluationText] = a:evaluation

    let l:range = ''
    let l:matchRange = ''
    if l:isSuccessful
	if g:SearchPosition_ShowRange
	    let l:range = a:line1 . ',' . a:line2
	    if a:line1 == 1 && a:line2 == line('$')
		let l:range = ''
	    elseif a:line1 == a:line2
		let l:range = a:line1
	    endif
	    if ! empty(l:range)
		let l:range = ':' . l:range . ' '
	    endif
	endif

	if g:SearchPosition_ShowMatchRange && a:lastMatchLnum != 0
	    redraw  " This is necessary because of the :redir done earlier.
	    let l:matchRange = s:EvaluateMatchRange(a:line1, a:line2, a:firstMatchLnum, a:lastMatchLnum)
	endif
    endif

    let l:patternMessage = ''
    if g:SearchPosition_ShowPattern
	let l:pattern = ingo#avoidprompt#TranslateLineBreaks('/' . (empty(a:pattern) ? @/ : escape(a:pattern, '/')) . '/')
	" Assumption: The evaluation message only contains printable ASCII
	" characters; we can thus simple use strlen() to determine the number of
	" occupied virtual columns. Otherwise, ingo#compat#strdisplaywidth()
	" could be used.
	let l:patternMessage = ingo#avoidprompt#Truncate(' for ' . l:pattern, (strlen(l:range) + strlen(l:evaluationText)))
    endif

    return [l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage]
endfunction
function! s:EchoResult( isSuccessful, range, evaluationText, matchRange, patternMessage )
    echo ''
    echon a:range
    execute 'echohl' (a:isSuccessful ?
    \	empty(g:SearchPosition_HighlightGroup) ? 'None' : g:SearchPosition_HighlightGroup :
    \	'WarningMsg'
    \)
    echon a:evaluationText . a:matchRange
    if a:isSuccessful | echohl None | endif
    echon a:patternMessage
    if ! a:isSuccessful | echohl None | endif
endfunction
function! s:Report( isSuccessful, range, evaluationText, matchRange, patternMessage )
    echomsg a:range . a:evaluationText . a:matchRange . a:patternMessage
    redraw

    call s:EchoResult(a:isSuccessful, a:range, a:evaluationText, a:matchRange, a:patternMessage)
    return 1
endfunction
function! s:ReportMultiple( results )
    for [l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage] in a:results
	echomsg l:range . l:evaluationText . l:matchRange . l:patternMessage
	redraw
    endfor

    for [l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage] in a:results
	call s:EchoResult(l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage)
    endfor
    return 1
endfunction
function! s:SearchAndEvaluate( line1, line2, pattern, isLiteral )
    " If the start / end of range is in a closed fold, Vim processes all lines
    " inside the fold, even when '.' or a fixed line number has been specified.
    " We correct the merely for output cosmetics, as the calculation is not
    " affected by this.
    let [l:startLnum, l:endLnum] = [ingo#range#NetStart(a:line1 ? max([a:line1, 1]) : 1), ingo#range#NetEnd(a:line2 ? min([a:line2, line('$')]) : line('$'))]
"****D echomsg '****' a:line1 a:line2
"****D echomsg '****' l:startLnum l:endLnum

    " Skip processing if there is no pattern.
    if empty(a:pattern) && (a:isLiteral || empty(@/))
	" Using an empty pattern would cause the previously used search pattern
	" to be used (if there is any).
	call ingo#err#Set(a:isLiteral ? 'Nothing selected' : 'E35: No previous regular expression')
	return 0
    endif

    let l:save_cursor = getpos('.')
    let l:cursorLine = line('.')
    let l:cursorVirtCol = virtcol('.')
    let l:isCursorOnClosedFold = (foldclosed(l:cursorLine) != -1)
    let l:isCursorInsideRange = (l:cursorLine >= l:startLnum && l:cursorLine <= l:endLnum)

    " This triple records matches relative to the current line or current closed
    " fold.
    let [l:matchesBefore, l:firstLnumBefore, l:lastLnumBefore]    = [0, 0x7FFFFFFF, 0]
    let [l:matchesCurrent, l:firstLnumCurrent, l:lastLnumCurrent] = [0, 0x7FFFFFFF, 0]
    let [l:matchesAfter, l:firstLnumAfter, l:lastLnumAfter]       = [0, 0x7FFFFFFF, 0]

    if l:cursorLine >= l:startLnum
	let l:lineBeforeCurrent = (l:isCursorInsideRange ?
	\   (l:isCursorOnClosedFold ? foldclosed(l:cursorLine) : l:cursorLine) - 1 :
	\   l:endLnum
	\)
	if l:lineBeforeCurrent >= l:startLnum
	    let [l:matchesBefore, l:firstLnumBefore, l:lastLnumBefore] = s:GetMatchesStats(l:startLnum . ',' . l:lineBeforeCurrent, a:pattern)
	endif
    endif

    if l:isCursorInsideRange
	" The range '.' represents either the current line or the entire current
	" closed fold.
	" We're not interested in matches on the current line if it's outside
	" the range to be examined.
	let [l:matchesCurrent, l:firstLnumCurrent, l:lastLnumCurrent] = s:GetMatchesStats('.', a:pattern)
    endif

    if l:cursorLine <= l:endLnum
	let l:lineAfterCurrent = (l:isCursorInsideRange ?
	\   (l:isCursorOnClosedFold ? foldclosedend(l:cursorLine) : l:cursorLine) + 1 :
	\   l:startLnum
	\)
	if l:lineAfterCurrent <= l:endLnum
	    let [l:matchesAfter, l:firstLnumAfter, l:lastLnumAfter] = s:GetMatchesStats(l:lineAfterCurrent . ',' . l:endLnum, a:pattern)
	endif
    endif

    let l:firstLnum = min([l:firstLnumBefore, l:firstLnumCurrent, l:firstLnumAfter])
    let l:lastLnum = max([l:lastLnumBefore, l:lastLnumCurrent, l:lastLnumAfter])
"****D echomsg '****' l:matchesBefore '/' l:matchesCurrent '/' l:matchesAfter 'in' string([l:firstLnum, l:lastLnum])

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
	while search(a:pattern, (l:before + l:exact + l:after ? '' : 'c'), l:cursorLine)
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
	    let l:matchLnum = search(a:pattern, 'n' . l:searchFlags, l:searchStopLine)
	    let l:isMatch = 0
	    if l:matchLnum == l:cursorLine  " This strict check is only needed for a match on the first line, as we use a stopline for all other searches that do not need to wrap around.
		let l:isMatch = 1
	    elseif l:matchLnum > 0 &&
	    \   l:matchLnum == l:cursorLine - 1 &&
	    \   search(a:pattern, 'ne' . l:searchFlags, l:searchStopLine) == l:cursorLine - 1
		" The match lies completely on the previous line; not what we
		" wanted (it should normally end on the current line). This
		" happens when a:pattern is a single newline. In this case, we
		" need to disallow matching at the current position (above the
		" actual current line) by dropping the "c" flag.
		let l:isMatch = (search(a:pattern, 'n', l:searchStopLine) == l:cursorLine)
	    endif

	    if l:isMatch
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

    return [
    \   l:startLnum, l:endLnum,
    \   l:firstLnum, l:lastLnum,
    \   s:Evaluate([l:matchesBefore, l:matchesCurrent, l:matchesAfter, l:before, l:exact, l:after])
    \]
endfunction
function! SearchPosition#SearchPosition( line1, line2, pattern, isLiteral )
    let [
    \   l:startLnum, l:endLnum,
    \   l:firstLnum, l:lastLnum,
    \   l:evaluation
    \] = s:SearchAndEvaluate(a:line1, a:line2, a:pattern, a:isLiteral)

    let [l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage] = s:GetReport(
    \   l:startLnum, l:endLnum,
    \   a:pattern,
    \   l:firstLnum, l:lastLnum,
    \   l:evaluation
    \)

    return s:Report(l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage)
endfunction
function! SearchPosition#SearchPositionMultiple( line1, line2, arguments )
    let l:patterns = []
    let l:arguments = a:arguments
    while ! empty(l:arguments)
	let [l:unescapedPattern, l:arguments] = ingo#cmdargs#pattern#ParseUnescaped(l:arguments, '\%(,\s*\(\%([[:alnum:]\\"|]\@![\x00-\xFF]\).*\)\)\?')
	call add(l:patterns, l:unescapedPattern)
    endwhile

    if len(l:patterns) == 1 && l:patterns[0] ==# a:arguments
	" No /.../,/.../ delimiters given; this is a list of literal whole
	" words.
	let l:patterns = map(
	\   split(a:arguments, ','),
	\   'ingo#regexp#FromLiteralText(v:val, 1, "")'
	\)
    endif

    call filter(l:patterns, '! empty(v:val)')

    if len(l:patterns) < 2
	call ingo#err#Set('Must pass at least two (comma-separated) {pattern}')
	return 0
    endif

    let l:results = []
    for l:pattern in l:patterns
	let [
	\   l:startLnum, l:endLnum,
	\   l:firstLnum, l:lastLnum,
	\   l:evaluation
	\] = s:SearchAndEvaluate(a:line1, a:line2, l:pattern, 0)

	call add(l:results, s:GetReport(
	\   l:startLnum, l:endLnum,
	\   l:pattern,
	\   l:firstLnum, l:lastLnum,
	\   l:evaluation
	\))
    endfor

    return s:ReportMultiple(l:results)
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

    if ! SearchPosition#SearchPosition(line("'["), line("']"), '', 0)
	call ingo#msg#ErrorMsg(ingo#err#Get())
    endif
endfunction

let s:pattern = ''
function! SearchPosition#SetCword( isWholeWord )
    let l:cword = expand('<cword>')
    if ! empty(l:cword)
	let s:pattern = ingo#regexp#FromLiteralText(l:cword, a:isWholeWord, '')
    endif
    return s:pattern
endfunction


function! SearchPosition#OperatorExpr()
    call SearchPosition#SavePosition()
    set opfunc=SearchPosition#Operator
    return 'g@'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
