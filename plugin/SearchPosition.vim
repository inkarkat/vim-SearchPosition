" SearchPosition.vim: Show relation to search pattern matches in range or buffer.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2008-2020 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchPosition') || (v:version < 700)
    finish
endif
let g:loaded_SearchPosition = 1

"- configuration --------------------------------------------------------------

if ! exists('g:SearchPosition_HighlightGroup')
    let g:SearchPosition_HighlightGroup = 'ModeMsg'
endif
if ! exists('g:SearchPosition_HighlightGroupWhat')
    let g:SearchPosition_HighlightGroupWhat = 'Title'
endif
if ! exists('g:SearchPosition_HighlightGroupWhere')
    let g:SearchPosition_HighlightGroupWhere = 'Directory'
endif

if ! exists('g:SearchPosition_ShowRange')
    let g:SearchPosition_ShowRange = 1
endif
if ! exists('g:SearchPosition_ShowPattern')
    let g:SearchPosition_ShowPattern = 1
endif
if ! exists('g:SearchPosition_ShowMatchRange')
    let g:SearchPosition_ShowMatchRange = 1
endif

if ! exists('g:SearchPosition_MatchRangeShowRelativeThreshold')
    let g:SearchPosition_MatchRangeShowRelativeThreshold = 'visible'
endif
if ! exists('g:SearchPosition_MatchRangeShowRelativeEndThreshold')
    let g:SearchPosition_MatchRangeShowRelativeEndThreshold = 9
endif


"- commands --------------------------------------------------------------------

command!       -range=% -nargs=? SearchPosition           if ! SearchPosition#SearchPosition(                          <line1>, <line2>, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command! -bang -range=% -nargs=? SearchPositionWithRepeat if ! SearchPosition#SearchPositionRepeat('Current', <bang>0, <line1>, <line2>, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command!       -range=% -nargs=? SearchPositionMultiple   if ! SearchPosition#SearchPositionMultiple(                  <line1>, <line2>, <q-args>) | echoerr ingo#err#Get() | endif

if v:version == 704 && has('patch542') || v:version > 704
command! -addr=windows        -range=% -bang -nargs=? WinSearchPosition  if ! SearchPosition#Elsewhere#Windows(  <bang>0, <line1>, <line2>, -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command! -addr=tabs           -range=% -bang -nargs=? TabSearchPosition  if ! SearchPosition#Elsewhere#Tabs(     <bang>0, <line1>, <line2>, -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command! -addr=arguments      -range=% -bang -nargs=? ArgSearchPosition  if ! SearchPosition#Elsewhere#Arguments(<bang>0, <line1>, <line2>, -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command! -addr=buffers        -range=% -bang -nargs=? BufSearchPosition  if ! SearchPosition#Elsewhere#Buffers(  <bang>0, <line1>, <line2>, -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
else
command!                               -bang -nargs=? WinSearchPosition  if ! SearchPosition#Elsewhere#Windows(  <bang>0, 1, winnr('$'),    -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command!                               -bang -nargs=? TabSearchPosition  if ! SearchPosition#Elsewhere#Tabs(     <bang>0, 1, tabpagenr('$'),-1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command!                               -bang -nargs=? ArgSearchPosition  if ! SearchPosition#Elsewhere#Arguments(<bang>0, 1, argc(),        -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
command!                               -bang -nargs=? BufSearchPosition  if ! SearchPosition#Elsewhere#Buffers(  <bang>0, 1, bufnr('$'),    -1, ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(<q-args>), 0) | echoerr ingo#err#Get() | endif
endif


"- mappings --------------------------------------------------------------------

nnoremap <silent> <expr> <Plug>SearchPositionOperator SearchPosition#OperatorExpr()
if ! hasmapto('<Plug>SearchPositionOperator', 'n')
    nmap <Leader><A-n> <Plug>SearchPositionOperator
endif


nnoremap <silent> <Plug>SearchPositionCurrent :SearchPositionWithRepeat<CR>
if ! hasmapto('<Plug>SearchPositionCurrent', 'n')
    nmap <A-n> <Plug>SearchPositionCurrent
endif
vnoremap <silent> <Plug>SearchPositionCurrent :SearchPositionWithRepeat<CR>
if ! hasmapto('<Plug>SearchPositionCurrent', 'v')
    vmap <A-n> <Plug>SearchPositionCurrent
endif
nnoremap <silent> <Plug>SearchPositionVerboseCurrent :SearchPositionWithRepeat!<CR>
if ! hasmapto('<Plug>SearchPositionVerboseCurrent', 'n')
    nmap g<A-n> <Plug>SearchPositionVerboseCurrent
endif
vnoremap <silent> <Plug>SearchPositionVerboseCurrent :SearchPositionWithRepeat!<CR>
if ! hasmapto('<Plug>SearchPositionVerboseCurrent', 'v')
    xmap g<A-n> <Plug>SearchPositionVerboseCurrent
endif

nnoremap <silent> <Plug>SearchPositionWholeCword :<C-u>if ! SearchPosition#SearchPositionRepeat('WholeCword', 0, (v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), SearchPosition#SetCword(1), 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>SearchPositionCword	 :<C-u>if ! SearchPosition#SearchPositionRepeat('Cword',      0, (v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), SearchPosition#SetCword(0), 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>SearchPositionWholeCWORD :<C-u>if ! SearchPosition#SearchPositionRepeat('WholeCWORD', 0, (v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), SearchPosition#SetCWORD(1), 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>SearchPositionCWORD	 :<C-u>if ! SearchPosition#SearchPositionRepeat('CWORD',      0, (v:count ? line('.') : 0), (v:count ? line('.') + v:count - 1 : 0), SearchPosition#SetCWORD(0), 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
if ! hasmapto('<Plug>SearchPositionWholeCword', 'n')
    nmap <A-m> <Plug>SearchPositionWholeCword
endif
if ! hasmapto('<Plug>SearchPositionCword', 'n')
    nmap g<A-m> <Plug>SearchPositionCword
endif
if ! hasmapto('<Plug>SearchPositionWholeCWORD', 'n')
    nmap ,<A-m> <Plug>SearchPositionWholeCWORD
endif
if ! hasmapto('<Plug>SearchPositionCWORD', 'n')
    nmap g,<A-m> <Plug>SearchPositionCWORD
endif
vnoremap <silent> <Plug>SearchPositionCword      :<C-u>if ! SearchPosition#SearchPositionRepeat('Cword', 0, 0, 0, ingo#regexp#FromLiteralText(ingo#selection#Get(), 0, ''), 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
if ! hasmapto('<Plug>SearchPositionCword', 'v')
    vmap <A-m> <Plug>SearchPositionCword
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
