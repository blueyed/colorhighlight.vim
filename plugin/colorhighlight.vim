" This Vim plugin helps with visualizing colors.
" 1. 'highlight' definitions are being colored in their own definition, try
"    it on your colorscheme file.
" 2. Highlight hex codes in their appropriate colors.
" Last Change: 2011 Mar 20
" Maintainer: Yuri Feldman <feldman.yuri1@gmail.com>,
"            Daniel Hahler (http://daniel.hahler.de/)
" URL: https://github.com/blueyed/colorhighlight.vim
"      Forked from: https://github.com/vim-scripts/hexHighlight.vim
"      (http://www.vim.org/scripts/script.php?script_id=2937)
" License: WTFPL - Do What The Fuck You Want To Public License.
" Email me if you'd like.

if ! exists("s:colored")
    let s:colored = 0
    let s:colorGroups = []
endif

map <Leader><F2> :call ColorHighlightToggle()<Return>
function! ColorHighlightToggle()
    if s:colored == 0 && len(s:colorGroups) == 0
        if &verbose >= 1 | echo "Highlighting colors..." | endif
        let colorGroup = 4
        let lineNumber = 0
        if has('gui_running')
            let canDoHex = 1
        else
            if &verbose > 0 | echo "Highlighting hex values only works with a graphical version of vim. Skipping." | endif
            let canDoHex = 0
        endif
        while lineNumber <= line("$")
            let currentLine = getline(lineNumber)
            let lineNumber += 1
            " Highlight 'hi(light)' lines in Vim mode files in their own
            " highlighting
            if &filetype == "vim"
                let m = matchstr(currentLine, '^\s*hi\(light\)\?\s\+\S\+\s\+')
                if m != ""
                    let colDef = substitute(currentLine, m, '', '')
                    let colDef = substitute(colDef, '^\s*\|\s*$', '', 'g') " trim
                    let colorDefinition = split(colDef)
                    " skip 'hi clear' lines
                    if colorDefinition[0] == "clear" | continue | endif
                    " remove 'default' keyword when applying the definition
                    if colorDefinition[0] == "default" | unlet colorDefinition[0] | endif
                    exe 'hi ColorHighlightGroup'.colorGroup.' '.escape(join(colorDefinition), '\\^$.*~[]')
                    exe 'let m = matchadd("ColorHighlightGroup'.colorGroup.'", "^".escape("'.escape(currentLine, '"').'", "\\^$.*~[]")."$", 25)'
                    let s:colorGroups += ['ColorHighlightGroup'.colorGroup]
                    let colorGroup += 1
                    continue " do not color hex codes in this line
                endif
            endif
            if canDoHex
                " highlight hex codes
                let hexLineMatch = 1
                while 1
                    let hexMatch = matchstr(currentLine, '#\(\x\x\x\)\{1,2}', 0, hexLineMatch)
                    if hexMatch == "" | break | endif
                    if len(hexMatch) == 3
                        let hexDef = hexMatch[0].hexMatch[0].hexMatch[1].hexMatch[1].hexMatch[2].hexMatch[2]
                    else
                        let hexDef = hexMatch
                    endif
                    exe 'hi ColorHighlightGroup'.colorGroup.' guifg='.hexDef.' guibg='.hexDef
                    exe 'let m = matchadd("ColorHighlightGroup'.colorGroup.'", "'.hexMatch.'", 25)'
                    let s:colorGroups += ['ColorHighlightGroup'.colorGroup]
                    let colorGroup += 1
                    let hexLineMatch += 1
                endwhile
              endif
        endwhile

        augroup ColorHighlight
          au!
          " TODO: should not reparse everything, but only updated lines or
          " something similar
          autocmd InsertLeave <buffer> call ColorHighlightToggle() | call ColorHighlightToggle()
        augroup END

        unlet lineNumber colorGroup
        let s:colored = 1
    else
        call ColorHighlightClear()
    endif
endfunction

function! ColorHighlightClear()
    if &verbose >= 1 | echo "Unhighlighting colors..." | endif
    let i = len(s:colorGroups)
    while i > 0
        let i -= 1
        exe 'highlight clear '.s:colorGroups[i]
        unlet s:colorGroups[i]
    endwhile
    call clearmatches()
    let s:colored = 0
    augroup ColorHighlight
      au!
    augroup END
endfunction
