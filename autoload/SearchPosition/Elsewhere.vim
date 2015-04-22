" SearchPosition/Elsewhere.vim: Show number of search pattern matches in other buffers.
"
" DEPENDENCIES:
"
" Copyright: (C) 2015 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	001	23-Apr-2015	file creation

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
"   List of [matchesCnt, uniqueLineCnt, firstLnum, lastLnum].
"******************************************************************************
    let l:save_view = winsaveview()
	let l:matchesCnt = 0
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
	endwhile
    call winrestview(l:save_view)
    return [l:matchesCnt, len(l:lines), l:firstLnum, l:lastLnum]
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
