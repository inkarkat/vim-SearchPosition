" SearchPosition/Elsewhere.vim: Show number of search pattern matches in other buffers.
"
" DEPENDENCIES:
"   - ingo/text.vim autoload script
"   - SearchPosition.vim autoload script
"
" Copyright: (C) 2015-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.003	28-Jul-2016	Move SearchPosition#Windows() to
"				SearchPosition#Elsewhere#Windows(). Add
"				a:skipWinNr argument.
"				Add a:searchResult.bufNr directly in
"				SearchPosition#Elsewhere#Count().
"				a:uniqueBufferNum is redundant, remove it.
"				Return additional a:isMatches from
"				SearchPosition#Elsewhere#Evaluate[One](). Use
"				that to turn off highlighting when there are no
"				matches.
"				Reimplement SearchPosition#Elsewhere#Count()
"				with :%s///gn by delegating to
"				SearchPosition#GetMatchesStats().
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
function! SearchPosition#Elsewhere#Count( firstLnum, lastLnum, pattern, uniqueMatches )
"******************************************************************************
"* PURPOSE:
"   Count all matches of a:pattern in the a:firstLnum, a:lastLnum range and
"   return them.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:firstLnum     Start line number to search.
"   a:lastLnum      End line number to search.
"   a:pattern       Regular expression to search. 'ignorecase', 'smartcase' and
"		    'magic' applies.
"   a:uniqueMatches Dictionary that counts unique matches across invocations.
"* RETURN VALUES:
"   Object with both buffer and search result attributes.
"******************************************************************************
    let l:uniqueMatches = {}
    let l:save_view = winsaveview()
	let [l:matchesCnt, l:firstLnum, l:lastLnum] = SearchPosition#GetMatchesStats(a:firstLnum . ',' . a:lastLnum, a:pattern, l:uniqueMatches)
    call winrestview(l:save_view)

    let [l:firstVisibleLnum, l:lastVisibleLnum] = (g:SearchPosition_MatchRangeShowRelativeThreshold ==# 'visible' ?
    \   ingo#window#dimensions#DisplayedLines() :
    \   [line('.') - g:SearchPosition_MatchRangeShowRelativeThreshold, line('.') + g:SearchPosition_MatchRangeShowRelativeThreshold]
    \)

    return {
    \   'bufNr': bufnr(''),
    \   'currentLnum': line('.'),
    \   'firstLnum': a:firstLnum,
    \   'lastLnum': a:lastLnum,
    \   'firstVisibleLnum': l:firstVisibleLnum,
    \   'lastVisibleLnum': l:lastVisibleLnum,
    \
    \   'matchesCnt': l:matchesCnt,
    \   'uniqueMatches': l:uniqueMatches,
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
    \   a:searchResult.firstLnum, a:searchResult.lastLnum,
    \   a:searchResult.firstMatchLnum, a:searchResult.lastMatchLnum,
    \   printf('%ss: %s has %s match%s%s',
    \       a:what,
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
	let l:uniqueEvaluation = (l:uniqueNum <= 1 ?
	\   '' :
	\   printf(' (%d different)', l:uniqueNum)
	\)

	let l:matchesCnt = ingo#collections#Reduce(
	\   l:positiveResults,
	\   'v:val[0] + v:val[1].matchesCnt',
	\   0
	\)

	let l:resultNum = len(a:searchResults)
	let l:evaluation = printf('%ss: %s buffers have %d match%s%s',
	\   a:what,
	\   (l:positiveResultNum == l:resultNum ? 'All' : printf('%d of %d', l:positiveResultNum, l:resultNum)),
	\   l:matchesCnt,
	\   (l:matchesCnt == 1 ? '' : 'es'),
	\   l:uniqueEvaluation
	\)
	return [1, 0, 0, 0, 0, l:evaluation]
    endif
endfunction

function! s:EvaluateAndReport( what, isVerbose, pattern, searchResults, uniqueMatches )
    if a:isVerbose
	let l:results = []
	let l:isShowPattern = g:SearchPosition_ShowPattern
	for l:searchResult in a:searchResults
	    let [
	    \   l:isMatches,
	    \   l:startLnum, l:endLnum,
	    \   l:firstLnum, l:lastLnum,
	    \   l:evaluation
	    \] = SearchPosition#Elsewhere#EvaluateOne(a:what, l:searchResult)

	    call add(l:results, SearchPosition#GetReport(
	    \   l:startLnum, l:endLnum,
	    \   a:pattern,
	    \   l:firstLnum, l:lastLnum,
	    \   l:startLnum, l:endLnum,
	    \   [(l:isMatches ? 1 : 2), l:evaluation],
	    \   g:SearchPosition_ShowRange, g:SearchPosition_ShowMatchRange, l:isShowPattern
	    \))
	    let l:isShowPattern = (len(a:searchResults) > 9 && l:searchResult == a:searchResults[-2] ? g:SearchPosition_ShowPattern : 0) " Only show the (identical) pattern at the beginning, and end if it's a long list.
	endfor

	return SearchPosition#ReportMultiple(l:results)
    else
	let [
	\   l:isMatches,
	\   l:startLnum, l:endLnum,
	\   l:firstLnum, l:lastLnum,
	\   l:evaluation
	\] = SearchPosition#Elsewhere#Evaluate(a:what, a:searchResults, a:uniqueMatches)

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




function! SearchPosition#Elsewhere#Iterate( searchResults, pattern, uniqueMatches )
    let l:result = SearchPosition#Elsewhere#Count(1, line('$'), a:pattern, a:uniqueMatches)
    call add(a:searchResults, l:result)
endfunction

function! SearchPosition#Elsewhere#WindowsLoop( alreadySearchedBuffers, searchResults, pattern, uniqueMatches )
    call ingo#actions#iterations#WinDo(a:alreadySearchedBuffers, function('SearchPosition#Elsewhere#Iterate'), a:searchResults, a:pattern, a:uniqueMatches)
endfunction
function! SearchPosition#Elsewhere#TabsLoop( alreadySearchedTabPages, alreadySearchedBuffers, searchResults, pattern, uniqueMatches )
    call ingo#actions#iterations#TabWinDo(a:alreadySearchedTabPages, a:alreadySearchedBuffers, function('SearchPosition#Elsewhere#Iterate'), a:searchResults, a:pattern, a:uniqueMatches)
endfunction

function! SearchPosition#Elsewhere#Windows( isVerbose, firstWinNr, lastWinNr, skipWinNr, pattern, isLiteral )
    if ! SearchPosition#IsValid(a:pattern, a:isLiteral)
	return 0
    elseif winnr('$') == 1 && a:skipWinNr == 1
	" There's only one window, and it should be excluded.
	call ingo#err#Set('No other windows')
	return 0
    endif


    let l:uniqueMatches = {}
    let l:alreadySearchedBuffers = (a:skipWinNr == -1 ? {} : {winbufnr(a:skipWinNr) : 1})
    let l:searchResults = []

    call ingo#actions#special#NoAutoChdir(function('SearchPosition#Elsewhere#WindowsLoop'), l:alreadySearchedBuffers, l:searchResults, a:pattern, l:uniqueMatches)

    let l:what = (a:skipWinNr == -1 ? '' : 'other ') . 'window'
    return s:EvaluateAndReport(l:what, a:isVerbose, a:pattern, l:searchResults, l:uniqueMatches)
endfunction
function! SearchPosition#Elsewhere#Tabs( isVerbose, firstTabPageNr, lastTabPageNr, skipTabPageNr, pattern, isLiteral )
    if ! SearchPosition#IsValid(a:pattern, a:isLiteral)
	return 0
    elseif tabpagenr('$') == 1 && a:skipTabPageNr == 1
	" There's only one tab page, and it should be excluded.
	call ingo#err#Set('No other tabs')
	return 0
    endif


    let l:uniqueMatches = {}
    let l:alreadySearchedTabPages = (a:skipTabPageNr == -1 ? {} : {a:skipTabPageNr : 1})
    let l:alreadySearchedBuffers = {}
    let l:searchResults = []

    call ingo#actions#special#NoAutoChdir(function('SearchPosition#Elsewhere#TabsLoop'), l:alreadySearchedTabPages, l:alreadySearchedBuffers, l:searchResults, a:pattern, l:uniqueMatches)

    let l:what = (a:skipTabPageNr == -1 ? '' : 'other ') . 'tab'
    return s:EvaluateAndReport(l:what, a:isVerbose, a:pattern, l:searchResults, l:uniqueMatches)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
