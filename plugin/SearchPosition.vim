" SearchPosition.vim: Show relation to search pattern matches in range or buffer. 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - SearchPosition.vim autoload script. 
"
" Copyright: (C) 2008-2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.10.011	08-Jan-2010	Moved functions from plugin to separate autoload
"				script.
"   1.10.010	08-Jan-2010	BUG: Catch non-existing items in s:evaluations
"				(e.g. "000100") that can be caused by e.g.
"				having \%# inside the search pattern. Warn about
"				"special atoms have distorted the tally" in such
"				cases. 
"   1.10.009	07-Jan-2010	BUG: Wrong reporting of additional occurrences
"				when the current line is outside the passed
"				range. 
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


"- commands and mappings ------------------------------------------------------
command! -range=% -nargs=? SearchPosition call SearchPosition#SearchPosition(<line1>, <line2>, <q-args>, 0)

if v:version < 702
    nnoremap <Plug>SearchPositionOperator mz:set opfunc=SearchPosition#Operator<CR>g@
else
    nnoremap <Plug>SearchPositionOperator m":set opfunc=SearchPosition#Operator<CR>g@
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

nnoremap <silent> <Plug>SearchPositionWholeCword :<C-u>call SearchPosition#SearchPosition((v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), SearchPosition#SetCword(1), 1)<CR>
nnoremap <silent> <Plug>SearchPositionCword	 :<C-u>call SearchPosition#SearchPosition((v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), SearchPosition#SetCword(0), 1)<CR>
if ! hasmapto('<Plug>SearchPositionWholeCword', 'n')
    nmap <silent> <A-m> <Plug>SearchPositionWholeCword
endif
if ! hasmapto('<Plug>SearchPositionCword', 'n')
    nmap <silent> g<A-m> <Plug>SearchPositionCword
endif
vnoremap <silent> <Plug>SearchPositionCword :<C-u>let save_unnamedregister=@@<CR>gvy: call SearchPosition#SearchPosition(0, 0, @@, 1)<CR>:let @@=save_unnamedregister<Bar>unlet save_unnamedregister<CR>
if ! hasmapto('<Plug>SearchPositionCword', 'v')
    vmap <silent> <A-m> <Plug>SearchPositionCword
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
