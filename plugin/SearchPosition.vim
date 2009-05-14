" SearchPosition.vim: Show where we are in relation to search pattern matches in
" range or buffer. 
"
" DESCRIPTION:
"   The mappings, command and operator provided by this plugin search a range or
"   the entire buffer for a (or the current search) pattern, and print a summary
"   of the number of occurrences above, below and on the current line. This
"   provides better orientation in a buffer without having to first jump from
"   search result to search result. 
"
"   In its simplest implementation
"	:nnoremap <A-n> :%s///gn<CR>
"	41 matches on 17 lines
"   prints the number of matches for the current search pattern. This plugin
"   builds on top of this, and prints information like:
"	On sole match in this line, 40 in following lines for /let/
"	3 matches before and 39 after this line; total 42 for /let/
"	:144,172 7 matches in this fold for /let/
"	4 matches before and 2 after cursor in this line; 30 and 19 overall;
"	total 49 for /let/
"
"   This plugin is similar to IndexedSearch.vim (vimscript#1682) by Yakov
"   Lerner. 
"
" USAGE:
" :[range]SearchPosition [{pattern}]
"			Show position of the search results for {pattern} (or the
"			current search pattern (@/) if {pattern} is omitted. All
"			lines in [range] (or entire buffer if omitted) are
"			considered, and the number of matches in relation to the
"			current cursor position is echoed to the command line. 
"
" <Leader><A-n>{motion}	Show position for the current search pattern in the
"			lines covered by {motion}. 
" [count]<A-n>		Show position for the current search pattern in the
"			entire buffer, or [count] following lines. 
" {Visual}<A-n>		Show position for the current search pattern in the
"			selected lines. 
"
"			The default mapping <A-n> was chosen because one often
"			invokes this when jumping to matches via n/N, so <A-n>
"			is easy to reach. Imagine 'n' stood for "next searches". 
"
" [count]<A-m>		Show position for the word under the cursor in the
"			entire buffer, or [count] following lines. 
"			Reuses the last used <cword> when on a blank line. 
" {Visual}<A-m>		Show position for the selected text in the entire
"			buffer. 
"
"			Imagine 'm' stood for "more occurrences". 
"
" INSTALLATION:
" DEPENDENCIES:
"   - EchoWithoutScrolling.vim autoload script (optional, only for showing
"     pattern). 
"
" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	004	15-May-2009	Added mappings for <cword> / selected word. 
"				A literal pattern (like <cword>) is now
"				converted to a regexp internally and included in
"				the report in its original, unmodified form. 
"	003	05-May-2009	BF: Must ':redir END' before evaluating captured
"				output from variable. 
"	002	10-Aug-2008	Decided on default mappings. 
"				Correcting wrong "1 matches" grammar. 
"	001	07-Aug-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_SearchPosition') || (v:version < 700)
    finish
endif
let g:loaded_SearchPosition = 1

"- configuration --------------------------------------------------------------
if ! exists('g:SearchPosition_HighlightGroup')
    let g:SearchPosition_HighlightGroup = 'ModeMsg'
endif
if ! exists('g:SearchPosition_ShowRange')
    let g:SearchPosition_ShowRange = 1
endif
if ! exists('g:SearchPosition_ShowPattern')
    let g:SearchPosition_ShowPattern = 1
endif


"- functions ------------------------------------------------------------------
function! s:GetMatchesCnt( range, pattern )
    let l:matchesCnt = 0

    redir => l:matches
    try
	silent execute a:range . 's/' . escape(a:pattern, '/') . '//gn'
	redir END
	let l:matchesCnt = matchstr( l:matches, '\n\zs\d\+' )
    catch /^Vim\%((\a\+)\)\=:E486/ " Pattern not found
    finally
	redir END
    endtry

    return l:matchesCnt
endfunction
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
\   '011011': 'On first match, {6} following in line, {3+6} overall', 
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
\   '110110': 'On last match, {4} previous in line, {1+4} overall', 
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

    let l:evaluation = s:evaluation[ l:matchVector ]
    let l:evaluation = substitute( l:evaluation, '{\%(\d\|+\)\+}', '\=s:ResolveParameters(a:matchResults, submatch(0))', 'g' )
    return substitute( l:evaluation, '1 matches' , '1 match', 'g' )
endfunction
function! s:Report( line1, line2, pattern, isLiteral, evaluation )
    let l:range = ''
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
    let l:pattern = ''
    if g:SearchPosition_ShowPattern
	let l:pattern = (a:isLiteral ? a:pattern : '/' . (empty(a:pattern) ? @/ : escape(a:pattern, '/')) . '/')
    endif

    redraw  " This is necessary because of the :redir done earlier. 
    echon l:range 
    execute (empty(g:SearchPosition_HighlightGroup) ? '' : 'echohl ' . g:SearchPosition_HighlightGroup)
    echon a:evaluation
    echohl None

    if ! empty(l:pattern)
	echon EchoWithoutScrolling#Truncate( ' for ' . l:pattern, (strlen(l:range) + strlen(a:evaluation)) )
    endif
endfunction
function! s:SearchPosition( line1, line2, pattern, isLiteral )
    let l:startLine = (a:line1 ? max([a:line1, 1]) : 1)
    let l:endLine = (a:line2 ? min([a:line2, line('$')]) : line('$'))
    " If the end of range is in a closed fold, VIM processes all lines inside
    " the fold, even when '.' or a fixed line number has been specified. We
    " correct the end line merely for output cosmetics, as the calculation is
    " not affected by this. 
    let l:endLine = (foldclosed(l:endLine) == -1 ? l:endLine : foldclosedend(l:endLine))
"****D echomsg '****' l:startLine l:endLine

    let l:pattern = (a:isLiteral ? '\V' . escape(a:pattern, '\') : a:pattern)

    let l:save_cursor = getpos('.')
    let l:cursorLine = line('.')
    let l:cursorVirtCol = virtcol('.')
    let l:isOnClosedFold = (foldclosed(l:cursorLine) != -1)

    " This triple records matches relative to the current line or current closed
    " fold. 
    let l:matchesBefore = 0
    let l:matchesCurrent = 0
    let l:matchesAfter = 0

    let l:lineBeforeCurrent = (l:isOnClosedFold ? foldclosed(l:cursorLine) : l:cursorLine) - 1
    if l:lineBeforeCurrent >= l:startLine
	let l:matchesBefore = s:GetMatchesCnt( l:startLine . ',' . l:lineBeforeCurrent, l:pattern )
    endif

    " The range '.' represents either the current line or the entire current
    " closed fold. 
    let l:matchesCurrent = s:GetMatchesCnt('.', l:pattern)

    let l:lineAfterCurrent = (l:isOnClosedFold ? foldclosedend(l:cursorLine) : l:cursorLine) + 1
    if l:lineAfterCurrent <= l:endLine
	let l:matchesAfter = s:GetMatchesCnt( l:lineAfterCurrent . ',' . l:endLine, l:pattern )
    endif
"****D echomsg '****' l:matchesBefore '/' l:matchesCurrent '/' l:matchesAfter

    let l:before = 0
    let l:exact = 0
    let l:after = 0
    if ! l:isOnClosedFold && l:cursorLine >= l:startLine && l:cursorLine <= l:endLine
	" We're not interested in matches on the current line if we're on a
	" closed fold; this would be just too much information. The user can
	" quickly open the fold and re-run the command if he's interested. 
	" We're also not interested if the current line is outside the passed
	" range. 
	call cursor(l:cursorLine, 1)
	" This triple records matches only in the current line (not current fold!),
	" split into before, on, and after cursor position. 
	while search( l:pattern, (l:before + l:exact + l:after ? '' : 'c'), l:cursorLine )
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
	call setpos('.', l:save_cursor)
"****D echomsg '****' l:before '/' l:exact '/' l:after
    endif

    call s:Report( l:startLine, l:endLine, a:pattern, a:isLiteral, s:Evaluate( [l:matchesBefore, l:matchesCurrent, l:matchesAfter, l:before, l:exact, l:after] ) )
endfunction

let s:pattern = ''
function! s:SetPattern( pattern )
    if ! empty(a:pattern)
	let s:pattern = a:pattern
    endif
    return s:pattern
endfunction

"- commands and mappings ------------------------------------------------------
command! -range=% -nargs=? SearchPosition call <SID>SearchPosition(<line1>, <line2>, <q-args>, 0)


function! s:SearchPositionOperator( type )
    " After the custom operator, the cursor will be positioned at the beginning
    " of the range, so if the motion goes backward, the cursor will move. For
    " this report-only command this is not desired, so we use a mark to pin the
    " cursor down. 
    normal! `z
    call s:SearchPosition(line("'["), line("']"), '', 0)
endfunction
nnoremap <Plug>SearchPositionOperator mz:set opfunc=<SID>SearchPositionOperator<CR>g@
if ! hasmapto('<Plug>SearchPositionOperator', 'n')
    nmap <silent> <Leader><A-n> <Plug>SearchPositionOperator
endif


nnoremap <silent> <Plug>SearchPositionCurrentInRange :SearchPosition<CR>
if ! hasmapto('<Plug>SearchPositionCurrentInRange', 'n')
    nmap <silent> <A-n> <Plug>SearchPositionCurrentInRange
endif
vnoremap <silent> <Plug>SearchPositionCurrentInRange :SearchPosition<CR>
if ! hasmapto('<Plug>SearchPositionCurrentInRange', 'v')
    vmap <silent> <A-n> <Plug>SearchPositionCurrentInRange
endif

nnoremap <silent> <Plug>SearchPositionCwordInRange :<C-u>call <SID>SearchPosition((v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), <SID>SetPattern(expand('<cword>')), 1)<CR>
if ! hasmapto('<Plug>SearchPositionCwordInRange', 'n')
    nmap <silent> <A-m> <Plug>SearchPositionCwordInRange
endif
vnoremap <silent> <Plug>SearchPositionCwordInRange :<C-u>let save_unnamedregister=@@<CR>gvy: call <SID>SearchPosition(0, 0, @@, 1)<CR>:let @@=save_unnamedregister<Bar>unlet save_unnamedregister<CR>
if ! hasmapto('<Plug>SearchPositionCwordInRange', 'v')
    vmap <silent> <A-m> <Plug>SearchPositionCwordInRange
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
