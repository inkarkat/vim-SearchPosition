" SearchPosition.vim: Show relation to search pattern matches in range or buffer.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"
" Copyright: (C) 2008-2023 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

function! SearchPosition#IsValid( pattern, isLiteral )
    " Skip processing if there is no pattern.
    if empty(a:pattern) && (a:isLiteral || empty(@/))
	" Using an empty pattern would cause the previously used search pattern
	" to be used (if there is any).
	call ingo#err#Set(a:isLiteral ? 'Nothing selected' : 'E35: No previous regular expression')
	return 0
    else
	return 1
    endif
endfunction
silent! call ingo#compat#DoesNotexist() " Need to preload, as autoloading within s:Record() fails with "E48: Not allowed in sandbox: function! ingo#compat#shiftwidth()", because the function is invoked as part of :sub-replace-expression.
function! s:Record( record, uniqueMatches )
    let l:lnum = line('.')
    " Assumption: We're invoked with ascending line numbers.
    if a:record[1] == 0
	let a:record[0] = l:lnum
	let a:record[1] = l:lnum
    else
	let a:record[1] = l:lnum
    endif

    let l:match = ingo#compat#DictKey(submatch(0))
    let a:uniqueMatches[l:match] = get(a:uniqueMatches, l:match, 0) + 1
endfunction
function! SearchPosition#GetMatchesStats( range, pattern, uniqueMatches )
    let l:matchesCnt = 0
    let l:record = [0x7FFFFFFF, 0]

    redir => l:matches
    try
	silent execute 'keepjumps' a:range . 's/' . escape(a:pattern, '/') . '/\=s:Record(l:record, a:uniqueMatches)/gn'
	redir END
	let l:matchesCnt = str2nr(matchstr( l:matches, '\n\zs\d\+' ))
    catch /^Vim\%((\a\+)\)\=:E486:/ " Pattern not found
    finally
	redir END
    endtry

    return [l:matchesCnt] + l:record
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
function! s:Evaluate( matchResults, uniqueMatches )
    let l:matchVector = join(map(copy(a:matchResults), '!!v:val'), '')

    if ! has_key(s:evaluation, l:matchVector)
	return [0, 'Special atoms have distorted the tally']
    endif

    let l:evaluation = s:evaluation[ l:matchVector ]
    let l:evaluation = substitute(l:evaluation, '{\%(\d\|+\)\+}', '\=s:ResolveParameters(a:matchResults, submatch(0))', 'g')

    let l:uniqueNum = len(a:uniqueMatches)
    let l:uniqueEvaluation = (l:uniqueNum <= 1 ?
    \   '' :
    \   printf(' (%d different)', l:uniqueNum)
    \)

    return [1, substitute(l:evaluation, '\C^1 matches' , '1 match', 'g') . l:uniqueEvaluation]
endfunction
function! s:TranslateLocation( lnum, currentLnum, lastLnum, firstVisibleLnum, lastVisibleLnum )
    if a:lnum == a:currentLnum
	return a:lnum
    elseif a:lnum == a:lastLnum
	return '$'
    elseif a:lnum == 1
	return '1'
    elseif a:lnum >= a:firstVisibleLnum && a:lnum <= a:lastVisibleLnum
	if a:currentLnum == 1
	    return a:lnum   " :2 looks better than :.+1
	endif

	let l:offset = a:lnum - a:currentLnum
	if ingo#compat#abs(l:offset) > a:lastLnum / 2
	    return a:lnum   " Prefer absolute numbers over offsets spanning more than half of the entire buffer.
	endif

	return (a:currentLnum == a:lastLnum ? '$' : '.') . (l:offset < 0 ? l:offset : '+' . l:offset)
    elseif a:lastLnum - a:lnum <= g:SearchPosition_MatchRangeShowRelativeEndThreshold
	return '$-' . (a:lastLnum - a:lnum)
    else
	return a:lnum
    endif
endfunction
function! SearchPosition#EvaluateMatchRange( line1, line2, firstMatchLnum, lastMatchLnum, currentLnum, lastLnum )
    if a:firstMatchLnum == a:line1 && a:lastMatchLnum == a:line2
	return ' spanning the entire ' . (a:line1 == 1 && a:line2 == a:lastLnum ? 'buffer' : 'range')
    endif

    let [l:firstVisibleLnum, l:lastVisibleLnum] = (g:SearchPosition_MatchRangeShowRelativeThreshold ==# 'visible' ?
    \   ingo#window#dimensions#DisplayedLines() :
    \   [a:currentLnum - g:SearchPosition_MatchRangeShowRelativeThreshold, a:currentLnum + g:SearchPosition_MatchRangeShowRelativeThreshold]
    \)

    let l:firstLocation = s:TranslateLocation(a:firstMatchLnum, a:currentLnum, a:lastLnum, l:firstVisibleLnum, l:lastVisibleLnum)
    if a:firstMatchLnum == a:lastMatchLnum
	return (a:firstMatchLnum == a:currentLnum ? '' : printf(' at %s', l:firstLocation))
    endif
    let l:lastLocation = s:TranslateLocation(a:lastMatchLnum, a:currentLnum, a:lastLnum, l:firstVisibleLnum, l:lastVisibleLnum)
    return printf(' within %s,%s', l:firstLocation, l:lastLocation)
endfunction
function! SearchPosition#GetReport( line1, line2, pattern, firstMatchLnum, lastMatchLnum, currentLnum, lastLnum, what, where, evaluation, isShowRange, isShowMatchRange, isShowPattern )
    let [l:isSuccessful, l:evaluationText] = a:evaluation

    let l:range = ''
    let l:matchRange = ''
    if l:isSuccessful
	if a:isShowRange && a:line1 != 0 && a:line2 != 0
	    let l:range = a:line1 . ',' . a:line2
	    if a:line1 == 1 && a:line2 == a:lastLnum
		let l:range = ''
	    elseif a:line1 == a:line2
		let l:range = a:line1
	    endif
	    if ! empty(l:range)
		let l:range = ':' . l:range . ' '
	    endif
	endif

	if a:isShowMatchRange && a:lastMatchLnum != 0
	    redraw  " This is necessary because of the :redir done earlier.
	    let l:matchRange = SearchPosition#EvaluateMatchRange(a:line1, a:line2, a:firstMatchLnum, a:lastMatchLnum, a:currentLnum, a:lastLnum)
	endif
    endif

    let l:pattern = ''
    if a:isShowPattern
	let l:pattern = ' for ' . ingo#avoidprompt#TranslateLineBreaks('/' . (empty(a:pattern) ? @/ : escape(a:pattern, '/')) . '/')
    endif

    return [l:isSuccessful, a:what, a:where, l:range, l:evaluationText, l:matchRange, l:pattern]
endfunction
function! s:Format( isHighlighted, isSuccessful, evaluationWhat, evaluationWhere, evaluationRange, evaluationText, matchRange, patternMessage )
	" Assumption: The evaluation message only contains printable ASCII
	" characters; we can thus simple use strlen() to determine the number of
	" occupied virtual columns. Otherwise, ingo#compat#strdisplaywidth()
	" could be used.
    if a:isHighlighted
	echo ''
	echon a:evaluationWhat . l:bufferName
	echon a:evaluationRange
	execute 'echohl' (a:isSuccessful ?
	\   (a:isSuccessful == 2 ?
	\       'None' :
	\	    empty(g:SearchPosition_HighlightGroup) ? 'None' : g:SearchPosition_HighlightGroup
	\   ) :
	\	'WarningMsg'
	\)
	echon a:evaluationText . a:matchRange
	if a:isSuccessful | echohl None | endif
	echon a:patternMessage
	if ! a:isSuccessful | echohl None | endif
    else
	echomsg a:evaluationWhat . l:bufferName . a:evaluationRange . a:evaluationText . a:matchRange . a:patternMessage
    endif
endfunction
function! s:ExpandWhere( result, maxLength )
    if ! empty(a:result[2])
	let l:bufferFilespec = fnamemodify(bufname(a:result[2]), ':~:.')
	let a:result[2] = ingo#avoidprompt#TruncateTo(l:bufferFilespec, a:maxLength - 1)
    endif
    return a:result
endfunction
function! s:FormatItem( itemIdx, result, length )
    let a:result[a:itemIdx] = printf('%-' . a:length . 's', a:result[a:itemIdx])
    return a:result
endfunction
function! s:FormatResults( results )
    call map(a:results, 's:ExpandWhere(v:val, ' . ingo#avoidprompt#MaxLength() / 3 . ')')
    let l:whereLength = max(map(copy(a:results), 'strlen(v:val[2])'))
    if l:whereLength > 0
	call map(a:results, 's:FormatItem(2, v:val, l:whereLength + 1)')
    endif

    let l:whatLength = max(map(copy(a:results), 'strlen(v:val[1])'))
    if l:whatLength > 0
	call map(a:results, 's:FormatItem(1, v:val, l:whatLength + 1)')
    endif

    return a:results
endfunction
function! s:EchoReport( report )
    echomsg join(a:report[1:], '')
endfunction
function! s:GetHl( setting )
    return (empty(a:setting) ? 'None' : a:setting)
endfunction
function! s:RenderReport( report )
    let [l:isSuccessful, l:evaluationWhat, l:evaluationWhere, l:evaluationRange, l:evaluationText, l:matchRange, l:patternMessage] = a:report

    echo ''

    call ingo#msg#HighlightN(l:evaluationWhat, s:GetHl(g:SearchPosition_HighlightGroupWhat))

    call ingo#msg#HighlightN(l:evaluationWhere, s:GetHl(g:SearchPosition_HighlightGroupWhere))

    call ingo#msg#HighlightN(l:evaluationRange)

    call ingo#msg#HighlightN(l:evaluationText . l:matchRange,
    \   l:isSuccessful ?
    \       (l:isSuccessful == 2 ?
    \           'None' :
    \           s:GetHl(g:SearchPosition_HighlightGroup)
    \       ) :
    \       'WarningMsg'
    \   )

    call ingo#msg#HighlightN(l:patternMessage)
endfunction
function! SearchPosition#Report( isSuccessful, evaluationWhat, evaluationWhere, evaluationRange, evaluationText, matchRange, patternMessage )
    let l:formattedReports = s:FormatResults([[a:isSuccessful, a:evaluationWhat, a:evaluationWhere, a:evaluationRange, a:evaluationText, a:matchRange, a:patternMessage]])
    call s:EchoReport(l:formattedReports[0])
    redraw
    call s:RenderReport(l:formattedReports[0])
    return 1
endfunction
function! SearchPosition#ReportMultiple( results )
    let l:formattedReports = s:FormatResults(a:results)
    for l:formattedReport in l:formattedReports
	call s:EchoReport(l:formattedReport)
	redraw
    endfor
    for l:formattedReport in l:formattedReports
	call s:RenderReport(l:formattedReport)
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
    if ! SearchPosition#IsValid(a:pattern, a:isLiteral)
	throw 'SearchPosition'
    endif

    let l:save_view = winsaveview()
    let l:cursorLine = line('.')
    let l:cursorVirtCol = virtcol('.')
    let l:isCursorOnClosedFold = (foldclosed(l:cursorLine) != -1)
    let l:isCursorInsideRange = (l:cursorLine >= l:startLnum && l:cursorLine <= l:endLnum)

    " This triple records matches relative to the current line or current closed
    " fold.
    let [l:matchesBefore, l:firstLnumBefore, l:lastLnumBefore]    = [0, 0x7FFFFFFF, 0]
    let [l:matchesCurrent, l:firstLnumCurrent, l:lastLnumCurrent] = [0, 0x7FFFFFFF, 0]
    let [l:matchesAfter, l:firstLnumAfter, l:lastLnumAfter]       = [0, 0x7FFFFFFF, 0]

    let l:uniqueMatches = {}
    if l:cursorLine >= l:startLnum
	let l:lineBeforeCurrent = (l:isCursorInsideRange ?
	\   (l:isCursorOnClosedFold ? foldclosed(l:cursorLine) : l:cursorLine) - 1 :
	\   l:endLnum
	\)
	if l:lineBeforeCurrent >= l:startLnum
	    let [l:matchesBefore, l:firstLnumBefore, l:lastLnumBefore] = SearchPosition#GetMatchesStats(l:startLnum . ',' . l:lineBeforeCurrent, a:pattern, l:uniqueMatches)
	endif
    endif

    if l:isCursorInsideRange
	" The range '.' represents either the current line or the entire current
	" closed fold.
	" We're not interested in matches on the current line if it's outside
	" the range to be examined.
	let [l:matchesCurrent, l:firstLnumCurrent, l:lastLnumCurrent] = SearchPosition#GetMatchesStats('.', a:pattern, l:uniqueMatches)
    endif

    if l:cursorLine <= l:endLnum
	let l:lineAfterCurrent = (l:isCursorInsideRange ?
	\   (l:isCursorOnClosedFold ? foldclosedend(l:cursorLine) : l:cursorLine) + 1 :
	\   l:startLnum
	\)
	if l:lineAfterCurrent <= l:endLnum
	    let [l:matchesAfter, l:firstLnumAfter, l:lastLnumAfter] = SearchPosition#GetMatchesStats(l:lineAfterCurrent . ',' . l:endLnum, a:pattern, l:uniqueMatches)
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

	call winrestview(l:save_view)
"****D echomsg '****' l:before '/' l:exact '/' l:after
    endif

    return [
    \   l:startLnum, l:endLnum,
    \   l:firstLnum, l:lastLnum,
    \   s:Evaluate([l:matchesBefore, l:matchesCurrent, l:matchesAfter, l:before, l:exact, l:after], l:uniqueMatches)
    \]
endfunction
function! SearchPosition#SearchPosition( line1, line2, pattern, isLiteral )
    try
	let [
	\   l:startLnum, l:endLnum,
	\   l:firstLnum, l:lastLnum,
	\   l:evaluation
	\] = s:SearchAndEvaluate(a:line1, a:line2, a:pattern, a:isLiteral)

	let [l:isSuccessful, l:evaluationWhat, l:evaluationWhere, l:evaluationRange, l:evaluationText, l:matchRange, l:patternMessage] = SearchPosition#GetReport(
	\   l:startLnum, l:endLnum,
	\   a:pattern,
	\   l:firstLnum, l:lastLnum,
	\   line('.'), line('$'),
	\   '', '',
	\   l:evaluation,
	\   g:SearchPosition_ShowRange, g:SearchPosition_ShowMatchRange, g:SearchPosition_ShowPattern
	\)

	return SearchPosition#Report(l:isSuccessful, l:evaluationWhat, l:evaluationWhere, l:evaluationRange, l:evaluationText, l:matchRange, l:patternMessage)
    catch /^SearchPosition/
	return 0
    endtry
endfunction
let s:record = []
let s:repeatCommand = ''
let s:repeatStage = 0
let s:repeatVerbose = 0
function! SearchPosition#SearchPositionRepeat( command, isVerbose, line1, line2, pattern, isLiteral )
    let l:newRecord = add(ingo#record#PositionAndLocation(0), empty(a:pattern) ? @/ : a:pattern)
    if a:isVerbose || a:command ==? 'cword' && s:record == l:newRecord && s:repeatCommand =~? '^\%(Whole\)\?cword$' " g<A-m> / g<A-w> on first use trigger cword/cWORD search, on repeat then switch to verbose reporting.
	if s:record == l:newRecord && (s:repeatCommand ==# a:command || s:repeatCommand =~? '^\%(Whole\)\?cword$')
	    let s:repeatStage += 1  " Verbose repeats just the same.
	else
	    let s:record = l:newRecord
	    let s:repeatStage = 1   " Initial mapping already starts with elsewhere search, as there is no verbose search in the current buffer.
	endif
	let s:repeatCommand = a:command
	let s:repeatVerbose = 1
	return s:SearchElsewhere(s:repeatVerbose, a:line1, a:line2, a:pattern, a:isLiteral)
    elseif s:record == l:newRecord && (s:repeatCommand ==# a:command || a:command ==? 'Wholecword' && s:repeatCommand ==? 'cword')
	let s:repeatStage += 1
	return s:SearchElsewhere(s:repeatVerbose, a:line1, a:line2, a:pattern, a:isLiteral)
    else
	let s:record = l:newRecord
	let s:repeatStage = 0
	let s:repeatCommand = a:command
	let s:repeatVerbose = a:isVerbose

	return SearchPosition#SearchPosition(a:line1, a:line2, a:pattern, a:isLiteral)
    endif
endfunction
function! s:SearchElsewhere( isVerbose, line1, line2, pattern, isLiteral )
    if s:repeatStage == 1
	if winnr('$') > 1
	    return SearchPosition#Elsewhere#Windows(a:isVerbose, 1, winnr('$'), (a:isVerbose ? -1 : winnr()), a:pattern, a:isLiteral)
	else
	    let s:repeatStage += 1
	endif
    endif
    if s:repeatStage == 2
	if tabpagenr('$') > 1
	    return SearchPosition#Elsewhere#Tabs(a:isVerbose, 1, tabpagenr('$'), (a:isVerbose ? -1 : tabpagenr()), a:pattern, a:isLiteral)
	else
	    let s:repeatStage += 1
	endif
    endif
    if s:repeatStage == 3
	if argc() > 0
	    return SearchPosition#Elsewhere#Arguments(a:isVerbose, 1, argc(), (a:isVerbose ? -1 : SearchPosition#Elsewhere#CurrentArgNr()), a:pattern, a:isLiteral)
	else
	    let s:repeatStage += 1
	endif
    endif
    if s:repeatStage == 4
	if ! ingo#buffer#IsEmptyVim()
	    return SearchPosition#Elsewhere#Buffers(a:isVerbose, 1, bufnr('$'), (a:isVerbose ? -1 : bufnr('')), a:pattern, a:isLiteral)
	else
	    let s:repeatStage += 1
	endif
    endif
    if a:isVerbose
	" Verbose cycles back to first repeat stage.
	let s:repeatStage = 1
	return s:SearchElsewhere(a:isVerbose, a:line1, a:line2, a:pattern, a:isLiteral)
    else
	" Else cycle back to normal search.
	let s:repeatStage = 0
	return SearchPosition#SearchPosition(a:line1, a:line2, a:pattern, a:isLiteral)
    endif
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

	call add(l:results, SearchPosition#GetReport(
	\   l:startLnum, l:endLnum,
	\   l:pattern,
	\   l:firstLnum, l:lastLnum,
	\   line('.'), line('$'),
	\   '', '',
	\   l:evaluation,
	\   g:SearchPosition_ShowRange, g:SearchPosition_ShowMatchRange, g:SearchPosition_ShowPattern
	\))
    endfor

    return SearchPosition#ReportMultiple(l:results)
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
function! SearchPosition#SetCWORD( isWholeWord )
    let l:cWORD = expand('<cWORD>')
    if ! empty(l:cWORD)
	let s:pattern = ingo#regexp#EscapeLiteralText(l:cWORD, '')
	if a:isWholeWord
	    let s:pattern = ingo#regexp#MakeWholeWORDSearch(l:cWORD, s:pattern)
	endif
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
