SEARCH POSITION
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

The mappings, command and operator provided by this plugin search a range or
the entire buffer for a pattern (defaulting to the last search pattern),
and print a summary of the number of occurrences above, below and on the
current line, e.g.:
```
    1 match after cursor in this line, 8 following, 2 in previous lines;
        total 10 within 11,42 for /\<SearchPosition\>/
```

    5 matches in this fold, 9 before, 6 following; total 21 spanning the
    entire buffer for /endif/

    On sole match in this line, 40 in following lines within 24,171 for /let/

    :144,172 7 matches in this fold for /let/

This provides better orientation in a buffer without having to first jump from
search result to search result.

### MOTIVATION

In its simplest implementation

    :nnoremap <A-n> :%s///gn<CR>

    41 matches on 17 lines
prints the number of matches for the last search pattern. This plugin
builds on top of this by providing more context with regards to the current
cursor position plus additional information.

### RELATED WORKS

- This plugin is similar to IndexedSearch.vim ([vimscript #1682](http://www.vim.org/scripts/script.php?script_id=1682)) by Yakov
  Lerner.
- vim-searchindex (https://github.com/google/vim-searchindex) hooks into the
  built-in search commands and also provides a separate g/ mapping to show the
  index of the current search and total counts.

USAGE
------------------------------------------------------------------------------

    :[range]SearchPosition [/][{pattern}][/]
                            Show position of the search results for {pattern} (or
                            the last search pattern (quote/) if {pattern} is
                            omitted). Without [/], only literal whole words are
                            matched. :search-args
                            All lines in [range] (or the entire buffer
                            if omitted) are considered, and the number of matches
                            in relation to the current cursor position is echoed
                            to the command line.

    :[range]SearchPositionMultiple /{pattern1}/,/{pattern2}/[,...]
    :[range]SearchPositionMultiple {word1},{word2}[,...]
                            Show positions and tallies of the search results for
                            {pattern1}, {pattern2}, ... Without [/] delimiters,
                            only literal whole {word1}, {word2}, ... are matched.
                            :search-args Useful to compare the number of
                            occurrences for multiple variants.

    :[range]WinSearchPosition[!] [/][{pattern}][/]
                            Show number and distribution of the search results
                            in all buffers shown in the current tab page. With
                            [!], shows a verbose report with match statistics
                            about every covered buffer, not just a summary.
                            If [range] is given only in windows for which the
                            window number lies in the [range].

    :[range]TabSearchPosition[!] [/][{pattern}][/]
                            Show number and distribution of the search results
                            in all buffers shown in all tab pages. With [!], shows
                            a verbose report with match statistics about every
                            covered buffer, not just a summary. If [range] is
                            given only in tab pages for which the tab page number
                            lies in the [range].

    :[range]ArgSearchPosition[!] [/][{pattern}][/]
                            Show number and distribution of the search results
                            in all buffers in the argument-list. With [!], shows
                            a verbose report with match statistics about every
                            covered buffer, not just a summary. If [range] is
                            given only covers those arguments.

    :[range]BufSearchPosition[!] [/][{pattern}][/]
                            Show number and distribution of the search results
                            in all listed buffers. With [!], shows a verbose
                            report with match statistics about every covered
                            buffer, not just a summary. If [range] is given only
                            covers those buffers.

    <Leader>ALT-n{motion}   Show position for the last search pattern in the
                            lines covered by {motion}.
    [count]ALT-n            Show position for the last search pattern in the
                            entire buffer, or [count] following lines.
    {Visual}ALT-n           Show position for the last search pattern in the
                            selected lines.

                            The default mapping ALT-n was chosen because one often
                            invokes this when jumping to matches via n/N, so ALT-n
                            is easy to reach. Imagine 'n' stood for "next
                            searches".

    [count]ALT-m            Show position for the whole word under the cursor in
                            the entire buffer, or [count] following lines.
                            Only whole keywords are searched for, like with the
                            star command.
    [count]g_ALT-m          Show position for the word under the cursor in the
                            entire buffer, or [count] following lines.
                            Also finds contained matches, like gstar.
                            When repeated at the same position, switches to
                            verbose reporting, like g_ALT-N.

    {Visual}ALT-m           Show position for the selected text in the entire
                            buffer.

                            Imagine 'm' stood for "more occurrences".
                            These mappings reuse the last used <cword> when issued
                            on a blank line.

    [count],_ALT-m          Show position for the whole (i.e. delimited by
                            whitespace) WORD under the cursor in the entire
                            buffer, or [count] following lines.
    [count]g,_ALT-m         Show position for the WORD under the cursor in the
                            entire buffer, or [count] following lines.
                            Also finds contained matches, like gstar.
                            When repeated at the same position, switches to
                            verbose reporting, like g_ALT-N.

                            These mappings reuse the last used <cWORD> when issued
                            on a blank line.

                            Repeats of any of the mappings at the same position
                            will extend the reporting to other (i.e. excluding the
                            current one)
                            - windows (:WinSearchPosition)
                            - tab pages (:TabSearchPosition)
                            - arguments (:ArgSearchPosition)
                            - loaded buffers (:BufSearchPosition)
                            skipping those sources that do not exist.

    g_ALT-n                 A repeat with a "g" prefix at the same position will
    g_ALT-m                 show a verbose report that shows match statistics
    g_,ALT-m                about every covered buffer, not just a summary.
                            g_ALT-n can also be used anywhere to start a verbose
                            report for all windows; g_ALT-m / g,_ALT-m cannot,
                            because they are overloaded with showing the position
                            of the word / WORD under the cursor.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-SearchPosition
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim SearchPosition*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.036 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

The highlight group for the report message can be set via

    let g:SearchPosition_HighlightGroup = 'ModeMsg'

To shorten the report message, the [range] and used search pattern can be
omitted from the message; by default, both are included in the message text:

    let g:SearchPosition_ShowRange = 1
    let g:SearchPosition_ShowPattern = 1

The report also shows in which range the matches fall. To turn this off:

    let g:SearchPosition_ShowMatchRange = 1

If the range falls entirely into the lines that are shown in the current
window, a relative range is used. To prefer a fixed threshold, or to turn this
off, use:

    let g:SearchPosition_MatchRangeShowRelativeThreshold = 10

The relative threshold at the end is determined via:

    let g:SearchPosition_MatchRangeShowRelativeEndThreshold = 10

If you want to use different mappings, map your keys to the
&lt;Plug&gt;SearchPosition\* mapping targets _before_ sourcing the script (e.g. in
your vimrc):

    nmap <Leader>,n <Plug>SearchPositionOperator
    nmap <Leader>n <Plug>SearchPositionCurrent
    vmap <Leader>n <Plug>SearchPositionCurrent
    nmap <Leader>m <Plug>SearchPositionWholeCword
    vmap <Leader>m <Plug>SearchPositionCword
    nmap <Leader>M <Plug>SearchPositionCword
    nmap <Leader>w <Plug>SearchPositionWholeCWORD
    nmap <Leader>W <Plug>SearchPositionCWORD

LIMITATIONS
------------------------------------------------------------------------------

- The summary always includes full lines, even if {motion} or the visual
  selection cover only parts of lines.

### CONTRIBUTING

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-SearchPosition/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 2.01    14-Nov-2024
- Don't repeat search if the search pattern has changed in the meantime.

##### 2.00    03-Apr-2020
- ENH: Add widening of search scope on mapping repeat at the same position,
  and verbose search result reporting.
- Add :WinSearchPosition, :TabSearchPosition, :ArgSearchPosition,
  :BufSearchPosition commands.
- BUG: {Visual}&lt;A-m&gt; uses selected text as pattern, not as literal text. Add
  escaping.
- ENH: Add [g],&lt;A-m&gt; variants of [g]&lt;A-m&gt; that use (whole) WORD instead of
  word.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.036!__

##### 1.30    23-Apr-2015
- BUG: Also need to account for cursor within closed fold for the start line
  number, not just the end.
- Also submit the plugin's result message (in unhighlighted form) to the
  message history (for recall and comparison).
- Add :SearchPositionMultiple command.
- Tweak s:TranslateLocation() for line 1:  :2 looks better than :.+1 there.
- Tweak s:TranslateLocation() for last line and use :$-N instead of :.-N
  there.
- BUG: Incorrect de-pluralization of "11 match[es]".

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.022!__

##### 1.21    08-Mar-2015
- ENH: Show relative range when the lines are shown in the current window with
  a new default configuration value of "visible" for
  g:SearchPosition\_MatchRangeShowRelativeThreshold. Use separate
  g:SearchPosition\_MatchRangeShowRelativeEndThreshold for threshold at the
  end.
- FIX: After "Special atoms have distorted the tally" warning, an additional
  stray (last actual) error is repeated. s:Report() also needs to return 1
  after such warning.
- BUG: "Special atoms have distorted the tally" warning instead of "No
  matches" when on first line. Must not allow previous matching line when that
  is identical to 0, the return value of search() when it fails.
- BUG: "Special atoms have distorted the tally" when doing
  :SearchPosition/\\n\\n/ on empty line. The special case for \\n matching is
  actually more complex; need to also ensure that the match doesn't lie
  completely on the previous line, and retry without the "c" search flag if it
  does.

##### 1.20    19-Jun-2014
- Abort commands and mappings on error.
- Use SearchPosition#OperatorExpr() to also handle [count] before the operator
  mapping.
- CHG: Also allow :[range]SearchPosition /{pattern}/ argument syntax; make
  previous :SearchPosition {pattern} do a literal whole word search.
- ENH: Also show range that the matches fall into; locations close to the
  current line in relative form.
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)).

__You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.020 (or higher)!__

##### 1.15    30-Sep-2011
- Use &lt;silent&gt; for &lt;Plug&gt; mapping instead of default mapping.

##### 1.14    12-Sep-2011
- Reuse: Use ingointegration#GetVisualSelection() instead of inline capture.

##### 1.13    08-Oct-2010
- BUG: The previous fix for the incorrect reporting of sole match in folded
  line was susceptible to non-local matches when current line is the first
  line.

##### 1.12    08-Oct-2010
- BUG: Visual mode &lt;A-m&gt; /Plug&gt;SearchPositionCword mapping on multi-line
  selection searched for ^@, not the newline character \\n.
- BUG: Incorrect reporting of sole match in folded line when the current line
  is empty and the pattern starts matching a newline character.
- Using SearchPosition#SavePosition() instead ofVim version-dependent) mark to
  keep the cursor at the position where the operator was invokedonly necessary
  with a backward {motion}).

##### 1.11    02-Jun-2010
- Appended "; total N" to evaluations that excluded the match on the cursor from
the "overall" count, as it was misleading what "overall" meant in this
context.

##### 1.10    08-Jan-2010
- Moved functions from plugin to separate autoload script.
- BUG: Wrong reporting of additional occurrences when the current line is
  outside the passed range.
- BUG: Catch non-existing items in evaluations that can be caused by e.g.
  having \\%# inside the search pattern. Warn about "special atoms have
  distorted the tally" in such cases.

##### 1.03    05-Jan-2010
- ENH: Offering a whole-word ALT-M mapping in addition to the former literal
search (which is now mapped to g\_ALT-M), like the star and gstar commands.

##### 1.02    11-Sep-2009
- BUG: Cannot set mark " in Vim 7.0 and 7.1; using mark z instead. This only
affected the &lt;Leader&gt;&lt;A-n&gt;{motion} command.

##### 1.01    19-Jun-2009
- The jumplist is not clobbered anymore by the :SearchPosition command.

##### 1.00    15-May-2009
- First published version.

##### 0.01    07-Aug-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2009-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
