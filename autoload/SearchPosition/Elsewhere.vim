" SearchPosition/Elsewhere.vim: Show number of search pattern matches in other buffers.
"
" DEPENDENCIES:
"   - ingo/text.vim autoload script
"
" Copyright: (C) 2015-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.50.003	28-Jul-2016	Move SearchPosition#Windows() to
"				SearchPosition#Elsewhere#Windows(). Add
"				a:skipWinNr argument.
"				Add a:searchResult.bufNr directly in
"				SearchPosition#Elsewhere#Count().
"				a:uniqueBufferNum is redundant, remove it.
"				Return additional a:isMatches from
"				SearchPosition#Elsewhere#Evaluate[One](). Use
"				that to turn off highlighting when there are no
"				matches.
"   1.50.002	22-Jul-2016	Pass a:uniqueMatches to
"				SearchPosition#Elsewhere#Count() to also tally
"				unique matches across invocations.
"				Return buffer information along with the search
"				matches, too.
"				Start implementing
"				SearchPosition#Elsewhere#Evaluate().
"   1.50.001	23-Apr-2015	file creation
let s:save_cpo = &cpo
set cpo&vim

" Modeled after ingo#text#frompattern#Get()
function! SearchPosition#Elsewhere#Count( firstLine, lastLine, pattern, uniqueMatches )
"******************************************************************************
"* PURPOSE:
"   Count all matches of a:pattern in the a:firstLine, a:lastLine range and
"   return them.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:firstLine     Start line number to search.
"   a:lastLine      End line number to search.
"   a:pattern       Regular expression to search. 'ignorecase', 'smartcase' and
"		    'magic' applies.
"   a:uniqueMatches Dictionary that counts unique matches across invocations.
"* RETURN VALUES:
"   Object with {bufNr, matchesCnt, uniqueMatches, uniqueLineCnt, firstLnum,
"   lastLnum} attributes.
"******************************************************************************
    let l:save_view = winsaveview()
	let l:matchesCnt = 0
	let l:uniqueMatches = {}
	let l:lines = {}
	let [l:firstLnum, l:lastLnum] = [0, 0]

	call cursor(a:firstLine, 1)
	let l:isFirst = 1
	while 1
	    let l:lnum = search(a:pattern, (l:isFirst ? 'c' : '') . 'W', a:lastLine)
	    if l:lnum == 0 | break | endif
	    if l:isFirst | let l:firstLnum = l:lnum | let l:isFirst = 0 | endif
	    let l:lastLnum = l:lnum
	    let l:matchesCnt +=1
	    let l:lines[l:lnum] = 1

	    let l:endPos = searchpos(a:pattern, 'cenW')
	    if l:endPos != [0, 0]
		let l:match = ingo#text#Get(getpos('.')[1:2], l:endPos)
		let l:uniqueMatches[l:match] = get(l:uniqueMatches, l:match, 0) + 1
		let a:uniqueMatches[l:match] = get(a:uniqueMatches, l:match, 0) + 1
	    endif
	endwhile
    call winrestview(l:save_view)

    let [l:firstVisibleLnum, l:lastVisibleLnum] = (g:SearchPosition_MatchRangeShowRelativeThreshold ==# 'visible' ?
    \   ingo#window#dimensions#DisplayedLines() :
    \   [line('.') - g:SearchPosition_MatchRangeShowRelativeThreshold, line('.') + g:SearchPosition_MatchRangeShowRelativeThreshold]
    \)

    return {
    \   'bufNr': bufnr(''),
    \   'currentLnum': line('.'),
    \   'lastLnum': line('$'),
    \   'firstVisibleLnum': l:firstVisibleLnum,
    \   'lastVisibleLnum': l:lastVisibleLnum,
    \
    \   'matchesCnt': l:matchesCnt,
    \   'uniqueMatches': l:uniqueMatches,
    \   'uniqueLineCnt': len(l:lines),
    \   'firstMatchLnum': l:firstLnum,
    \   'lastMatchLnum': l:lastLnum
    \}
endfunction

function! s:BufferIdentification( bufNr )
    " TODO: Include (shortened) buffer name, but truncated to 1/3 of &columns
    return printf('#%d', a:bufNr)
endfunction
function! SearchPosition#Elsewhere#EvaluateOne( what, searchResult )
    let l:uniqueNum = len(a:searchResult.uniqueMatches)
    let l:uniqueEvaluation = (l:uniqueNum <= 1 ?
    \   '' :
    \   printf(' (%d different)', l:uniqueNum)
    \)
    let l:isMatches = (a:searchResult.matchesCnt > 0)
    return [
    \   l:isMatches,
    \   1, a:searchResult.lastLnum,
    \   a:searchResult.firstMatchLnum, a:searchResult.lastMatchLnum,
    \   printf('%s has %s match%s%s',
    \       s:BufferIdentification(a:searchResult.bufNr),
    \       (l:isMatches ? a:searchResult.matchesCnt : 'no'),
    \       (a:searchResult.matchesCnt == 1 ? '' : 'es'),
    \       l:uniqueEvaluation
    \   )
    \]
endfunction
function! SearchPosition#Elsewhere#Evaluate( what, searchResults, uniqueGlobalMatches )
    let l:positiveResults = filter(copy(a:searchResults), 'v:val.matchesCnt > 0')

    let l:positiveResultNum = len(l:positiveResults)
    if l:positiveResultNum == 0
	return [0, 0, 0, 0, 0, printf('No matches in %ss', a:what)]
    elseif l:positiveResultNum == 1
	return SearchPosition#Elsewhere#EvaluateOne(a:what, l:positiveResults[0])
    else
	let l:uniqueNum = len(a:uniqueGlobalMatches)
	let l:uniqueEvaluation = (l:uniqueNum == 1 ?
	\   '' :
	\   printf(' (%d different)', l:uniqueNum)
	\)

	let l:matchesCnt = ingo#collections#Reduce(
	\   l:positiveResults,
	\   'v:val[0] + v:val[1].matchesCnt',
	\   0
	\)

	let l:resultNum = len(a:searchResults)
	let l:evaluation = printf('%s buffers have %d match%s%s',
	\   (l:positiveResultNum == l:resultNum ? 'All' : printf('%d of %d', l:positiveResultNum, l:resultNum)),
	\   l:matchesCnt,
	\   (l:matchesCnt == 1 ? '' : 'es'),
	\   l:uniqueEvaluation
	\)
	return [1, 0, 0, 0, 0, l:evaluation]
    endif
endfunction



function! SearchPosition#Elsewhere#Windows( isVerbose, firstWinNr, lastWinNr, skipWinNr, pattern, isLiteral )
    if ! SearchPosition#IsValid(a:pattern, a:isLiteral)
	return 0
    endif

    let l:uniqueMatches = {}
    let l:alreadySearchedBuffers = (a:skipWinNr == -1 ? {} : {a:skipWinNr : 1})
    let l:searchResults = []

    let l:originalWinNr = winnr()
    let l:previousWinNr = winnr('#') ? winnr('#') : 1
    let l:originalBufNr = bufnr('')
    if winnr('$') == 1 && has_key(l:alreadySearchedBuffers, l:originalBufNr)
	" There's only one window, and it should be excluded.
	call ingo#err#Set('No other windows')
	return 0
    endif



    " By entering a window, its height is potentially increased from 0 to 1 (the
    " minimum for the current window). To avoid any modification, save the window
    " sizes and restore them after visiting all windows.
    let l:originalWindowLayout = winrestcmd()

    " Unfortunately, restoring the 'autochdir' option clobbers any temporary CWD
    " override. So we may have to restore the CWD, too.
    let l:save_cwd = getcwd()
    let l:chdirCommand = (exists('*haslocaldir') && haslocaldir() ? 'lchdir!' : 'chdir!')

    " The 'autochdir' option adapts the CWD, so any (relative) filepath to the
    " filename in the other window would be omitted. Temporarily turn this off;
    " may be a little bit faster, too.
    if exists('+autochdir')
	let l:save_autochdir = &autochdir
	set noautochdir
    endif

    try
	for l:winNr in range(1, winnr('$'))
	    let l:bufNr = winbufnr(l:winNr)
	    if l:bufNr != l:originalBufNr &&
	    \   ! has_key(l:alreadySearchedBuffers, l:bufNr)
		execute 'noautocmd' l:winNr . 'wincmd w'

		call add(l:searchResults, SearchPosition#Elsewhere#Count(1, line('$'), a:pattern, l:uniqueMatches))
	    endif
	endfor
    finally
	noautocmd execute l:previousWinNr . 'wincmd w'
	noautocmd execute l:originalWinNr . 'wincmd w'
	silent! execute l:originalWindowLayout

	if exists('l:save_autochdir')
	    let &autochdir = l:save_autochdir
	endif
	if getcwd() !=# l:save_cwd
	    execute l:chdirCommand ingo#compat#fnameescape(l:save_cwd)
	endif
    endtry



    if a:isVerbose
	let l:results = []
	let l:isShowPattern = g:SearchPosition_ShowPattern
	for l:searchResult in l:searchResults
	    let [
	    \   l:isMatches,
	    \   l:startLnum, l:endLnum,
	    \   l:firstLnum, l:lastLnum,
	    \   l:evaluation
	    \] = SearchPosition#Elsewhere#EvaluateOne('window', l:searchResult)

	    call add(l:results, SearchPosition#GetReport(
	    \   l:startLnum, l:endLnum,
	    \   a:pattern,
	    \   l:firstLnum, l:lastLnum,
	    \   l:startLnum, l:endLnum,
	    \   [(l:isMatches ? 1 : 2), l:evaluation],
	    \   g:SearchPosition_ShowRange, g:SearchPosition_ShowMatchRange, l:isShowPattern
	    \))
	    let l:isShowPattern = (len(l:searchResults) > 9 && l:searchResult == l:searchResults[-2] ? g:SearchPosition_ShowPattern : 0) " Only show the (identical) pattern at the beginning, and end if it's a long list.
	endfor

	return SearchPosition#ReportMultiple(l:results)
    else
	let [
	\   l:isMatches,
	\   l:startLnum, l:endLnum,
	\   l:firstLnum, l:lastLnum,
	\   l:evaluation
	\] = SearchPosition#Elsewhere#Evaluate('window', l:searchResults, l:uniqueMatches)

	let [l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage] = SearchPosition#GetReport(
	\   l:startLnum, l:endLnum,
	\   a:pattern,
	\   l:firstLnum, l:lastLnum,
	\   l:startLnum, l:endLnum,
	\   [1, l:evaluation],
	\   g:SearchPosition_ShowRange, g:SearchPosition_ShowMatchRange, g:SearchPosition_ShowPattern
	\)

	return SearchPosition#Report(l:isSuccessful, l:range, l:evaluationText, l:matchRange, l:patternMessage)
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
