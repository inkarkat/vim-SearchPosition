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
"   1.03.008	05-Jan-2010	ENH: Offering a whole-word ALT-M mapping and the
"				old literal search via g_ALT-M, like the |star|
"				and |gstar| commands. 
"				Using ingosearch.vim for conversion of literal
"				text to search pattern, as enclosing in \<...\>
"				is non-trivial. 
"				Refactored s:SetPattern() to do the expansion of
"				<cword> itself. 
"   1.02.007	11-Sep-2009	BUG: Cannot set mark " in Vim 7.0 and 7.1; using
"				mark z instead. 
"   1.01.006	19-Jun-2009	Using :keepjumps to avoid that the :substitute
"				command in s:GetMatchesCnt() clobbers the
"				jumplist. 
"   1.01.005	18-Jun-2009	Replaced temporary mark z with mark " and using
"				g` command to avoid clobbering jumplist. 
"   1.00.004	15-May-2009	Added mappings for <cword> / selected word. 
"				A literal pattern (like <cword>) is now
"				converted to a regexp internally and included in
"				the report in its original, unmodified form. 
"				BF: Translating line breaks in search pattern
"				via EchoWithoutScrolling#TranslateLineBreaks()
"				to avoid messed up report message. 
"				Split off documentation. 
"	003	05-May-2009	BF: Must ':redir END' before evaluating captured
"				output from variable. 
"	002	10-Aug-2008	Decided on default mappings. 
"				Correcting wrong "1 matches" grammar. 
"	001	07-Aug-2008	file creation

" Avoid installing twice or when in unsupported Vim version. 
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
	silent execute 'keepjumps' a:range . 's/' . escape(a:pattern, '/') . '//gn'
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
function! s:Report( line1, line2, pattern, evaluation )
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
	let l:pattern = EchoWithoutScrolling#TranslateLineBreaks('/' . (empty(a:pattern) ? @/ : escape(a:pattern, '/')) . '/')
    endif

    redraw  " This is necessary because of the :redir done earlier. 
    echon l:range 
    execute (empty(g:SearchPosition_HighlightGroup) ? '' : 'echohl ' . g:SearchPosition_HighlightGroup)
    echon a:evaluation
    echohl None

    if ! empty(l:pattern)
	" Assumption: The evaluation message only contains printable ASCII
	" characters; we can thus simple use strlen() to determine the number of
	" occupied virtual columns. Otherwise,
	" EchoWithoutScrolling#DetermineVirtColNum() could be used. 
	echon EchoWithoutScrolling#Truncate( ' for ' . l:pattern, (strlen(l:range) + strlen(a:evaluation)) )
    endif
endfunction
function! s:SearchPosition( line1, line2, pattern, isLiteral )
    let l:startLine = (a:line1 ? max([a:line1, 1]) : 1)
    let l:endLine = (a:line2 ? min([a:line2, line('$')]) : line('$'))
    " If the end of range is in a closed fold, Vim processes all lines inside
    " the fold, even when '.' or a fixed line number has been specified. We
    " correct the end line merely for output cosmetics, as the calculation is
    " not affected by this. 
    let l:endLine = (foldclosed(l:endLine) == -1 ? l:endLine : foldclosedend(l:endLine))
"****D echomsg '****' l:startLine l:endLine

    " Skip processing if there is no pattern. 
    if empty(a:pattern) && (a:isLiteral || empty(@/))
	" This check is necessary not just to better inform the user, but also
	" because the two methods to tally overall and matches in the current
	" line react different to an empty literal pattern (/\V/): %s/\V//gn
	" matches every character and once for an empty line, but search('\V')
	" does not move the cursor and does not match in an empty line. 
	" This discrepance caused this to report being "in this fold" when
	" executed with a literal empty pattern on an empty line. 
	echohl ErrorMsg
	let v:errmsg = (a:isLiteral ? 'Nothing selected' : 'E35: No previous regular expression')
	echomsg v:errmsg
	echohl None
	return
    endif

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
	let l:matchesBefore = s:GetMatchesCnt( l:startLine . ',' . l:lineBeforeCurrent, a:pattern )
    endif

    " The range '.' represents either the current line or the entire current
    " closed fold. 
    let l:matchesCurrent = s:GetMatchesCnt('.', a:pattern)

    let l:lineAfterCurrent = (l:isOnClosedFold ? foldclosedend(l:cursorLine) : l:cursorLine) + 1
    if l:lineAfterCurrent <= l:endLine
	let l:matchesAfter = s:GetMatchesCnt( l:lineAfterCurrent . ',' . l:endLine, a:pattern )
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
	call setpos('.', l:save_cursor)
"****D echomsg '****' l:before '/' l:exact '/' l:after
    endif

    call s:Report( l:startLine, l:endLine, a:pattern, s:Evaluate( [l:matchesBefore, l:matchesCurrent, l:matchesAfter, l:before, l:exact, l:after] ) )
endfunction

"- commands and mappings ------------------------------------------------------
command! -range=% -nargs=? SearchPosition call <SID>SearchPosition(<line1>, <line2>, <q-args>, 0)


function! s:SearchPositionOperator( type )
    " After the custom operator, the cursor will be positioned at the beginning
    " of the range, so if the motion goes backward, the cursor will move. For
    " this report-only command this is not desired, so we use a mark to pin the
    " cursor down. 
    if v:version < 702
	normal! g`z
    else
	normal! g`"
    endif
    call s:SearchPosition(line("'["), line("']"), '', 0)
endfunction
if v:version < 702
    nnoremap <Plug>SearchPositionOperator mz:set opfunc=<SID>SearchPositionOperator<CR>g@
else
    nnoremap <Plug>SearchPositionOperator m":set opfunc=<SID>SearchPositionOperator<CR>g@
endif
if ! hasmapto('<Plug>SearchPositionOperator', 'n')
    nmap <silent> <Leader><A-n> <Plug>SearchPositionOperator
endif


nnoremap <silent> <Plug>SearchPositionCurrent :SearchPosition<CR>
if ! hasmapto('<Plug>SearchPositionCurrent', 'n')
    nmap <silent> <A-n> <Plug>SearchPositionCurrent
endif
vnoremap <silent> <Plug>SearchPositionCurrent :SearchPosition<CR>
if ! hasmapto('<Plug>SearchPositionCurrent', 'v')
    vmap <silent> <A-n> <Plug>SearchPositionCurrent
endif

let s:pattern = ''
function! s:SetCword( isWholeWord )
    let l:cword = expand('<cword>')
    if ! empty(l:cword)
	let s:pattern = ingosearch#LiteralTextToSearchPattern(l:cword, a:isWholeWord, '')
    endif
    return s:pattern
endfunction
nnoremap <silent> <Plug>SearchPositionWholeCword :<C-u>call <SID>SearchPosition((v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), <SID>SetCword(1), 1)<CR>
nnoremap <silent> <Plug>SearchPositionCword	 :<C-u>call <SID>SearchPosition((v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), <SID>SetCword(0), 1)<CR>
if ! hasmapto('<Plug>SearchPositionWholeCword', 'n')
    nmap <silent> <A-m> <Plug>SearchPositionWholeCword
endif
if ! hasmapto('<Plug>SearchPositionCword', 'n')
    nmap <silent> g<A-m> <Plug>SearchPositionCword
endif
vnoremap <silent> <Plug>SearchPositionCword :<C-u>let save_unnamedregister=@@<CR>gvy: call <SID>SearchPosition(0, 0, @@, 1)<CR>:let @@=save_unnamedregister<Bar>unlet save_unnamedregister<CR>
if ! hasmapto('<Plug>SearchPositionCword', 'v')
    vmap <silent> <A-m> <Plug>SearchPositionCword
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
