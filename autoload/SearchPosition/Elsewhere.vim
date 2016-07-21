" SearchPosition/Elsewhere.vim: Show number of search pattern matches in other buffers.
"
" DEPENDENCIES:
"   - ingo/text.vim autoload script
"
" Copyright: (C) 2015 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.50.001	23-Apr-2015	file creation

" Modeled after ingo#text#frompattern#Get()
function! SearchPosition#Elsewhere#Count( firstLine, lastLine, pattern )
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
"* RETURN VALUES:
"   Object with {matchesCnt, uniqueMatches, uniqueLineCnt, firstLnum,
"   lastLnum} attributes.
"******************************************************************************
    let l:save_view = winsaveview()
	let l:matchesCnt = 0
	let l:matches = {}
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
		let l:matches[l:match] = get(l:matches, l:match, 0) + 1
	    endif
	endwhile
    call winrestview(l:save_view)
    return {'matchesCnt': l:matchesCnt, 'uniqueMatches': l:matches, 'uniqueLineCnt': len(l:lines), 'firstLnum': l:firstLnum, 'lastLnum': l:lastLnum}
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
