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
"   Object with {matchesCnt, uniqueMatches, uniqueLineCnt, firstLnum,
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
    let l:uniqueEvaluation = (l:uniqueNum == 1 ?
    \   '' :
    \   printf(' (%d different)', l:uniqueNum)
    \)
    return [
    \   1, a:searchResult.lastLnum,
    \   a:searchResult.firstMatchLnum, a:searchResult.lastMatchLnum,
    \   printf('%s has %d match%s%s',
    \       s:BufferIdentification(a:searchResult.bufNr),
    \       a:searchResult.matchesCnt,
    \       (a:searchResult.matchesCnt == 1 ? '' : 'es'),
    \       l:uniqueEvaluation
    \   )
    \]
endfunction
function! SearchPosition#Elsewhere#Evaluate( what, searchResults )
    let l:positiveResults = filter(copy(a:searchResults), 'v:val.matchesCnt > 0')

    let l:positiveResultNum = len(l:positiveResults)
    if l:positiveResultNum == 0
	return [0, 0, 0, 0, printf('No matches in %ss', a:what)]
    elseif l:positiveResultNum == 1
	return SearchPosition#Elsewhere#EvaluateOne(a:what, l:positiveResults[0])
    else
	return [0, 0, 0, 0, printf('TODO:match summary')]
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
