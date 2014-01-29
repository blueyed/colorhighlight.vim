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

function! ColorSyntaxHighlightToggle()
    if s:colored == 0 && len(s:colorGroups) == 0
        if &verbose >= 1 | echo "Highlighting colors..." | endif
        return ColorSyntaxHighlightOn()
    else
        if &verbose >= 1 | echo "Clearing highlights..." | endif
        return ColorSyntaxHighlightClear()
    endif
endfunction

function! ColorSyntaxHighlightOn()
    let s:colorGroup = 4
    let lineNumber = 1
    let hexMatchCount = 0
    let hiMatchCount = 0
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
        " color definition
        if &filetype == "vim"
            " TODO: merge into colorizer
            let colDef = ''
            let m = matchstr(currentLine, '^\s*hi\(light\)\?\s\+\(clear\)\@!\(\S\+\)\s\+')
            if m != ""
                let colDef = substitute(currentLine, m, '', '')
                let colDef = substitute(colDef, '^\s*\|\s*$', '', 'g') " trim
            else
                " No 'highlight match', check for / handle output from ':highlight'.
                let m2 = matchlist(currentLine, '^\S\+ \+xxx \(.*\)$')
                if len(m2)
                    " check for 'links to Foo'
                    if m2[1] =~# '^links to '
                        let highlight = 'link %s '.m2[1][9:]
                        call s:AddHighlight(highlight, '^'.escape(currentLine, '\^$.*~[]').'$')
                        continue
                    endif
                    let colDef = m2[1]
                endif
            endif
            if colDef != ''
                let colorDefinition = split(colDef)

                " remove 'default' keyword when applying the definition
                if colorDefinition[0] =~ "^def\(ault\)?" | unlet colorDefinition[0] | endif
                " remove 'xxx' (in output from :highlight)
                if colorDefinition[0] == "xxx" | unlet colorDefinition[0] | endif

                let colorValues = copy(colorDefinition)
                call filter(colorValues, 'v:val =~ ''=''')
                if empty(colorValues)
                    " There are no color value pairs, but it might be a link
                    " to another group.
                    if ! empty(colorDefinition) && colorDefinition[0] == 'link'
                        let highlight = 'link %s '.colorDefinition[-1]
                    else
                        continue
                    endif
                else
                    let highlight = '%s '.join(colorDefinition)
                endif
                call s:AddHighlight(highlight, '^'.escape(currentLine, '\^$.*~[]').'$')
                let hiMatchCount += 1
                continue " do not color hex codes in this line
            endif
        endif
        if canDoHex
            " highlight hex codes
            let hexCountInLine = 0
            while 1
                let hexMatch = matchstr(currentLine, '#\(\x\x\x\)\{1,2}', 0, hexCountInLine)
                if hexMatch == "" | break | endif
                if len(hexMatch) == 4
                    let hexDef = hexMatch[0].hexMatch[1].hexMatch[1].hexMatch[2].hexMatch[2].hexMatch[3].hexMatch[3]
                else
                    let hexDef = hexMatch
                endif
                call s:AddHighlight('%s guifg='.hexDef.' guibg='.hexDef, hexMatch)
                let hexCountInLine += 1
            endwhile
            let hexMatchCount += hexCountInLine
        endif
    endwhile
    if &verbose >= 1 | echo "Marked" hiMatchCount "highlight lines and" hexMatchCount "hex codes." | endif

    augroup ColorSyntaxHighlight
      au!
      " TODO: should not reparse everything, but only updated lines or
      " something similar
      autocmd InsertLeave <buffer> call ColorSyntaxHighlightToggle() | call ColorSyntaxHighlightToggle()
    augroup END

    unlet lineNumber
    let s:colored = 1
endfunction

function! s:AddHighlight(highlight, match)
    let colorGroupName = 'ColorSyntaxHighlightGroup'.s:colorGroup
    exe 'hi '.printf(a:highlight, colorGroupName)
    exe 'let m = matchadd("'.colorGroupName.'", "'.a:match.'", 25)'
    let s:colorGroups += [colorGroupName]
    let s:colorGroup += 1
endfunction

function! ColorSyntaxHighlightClear()
    let i = len(s:colorGroups)
    while i > 0
        let i -= 1
        exe 'highlight clear '.s:colorGroups[i]
        unlet s:colorGroups[i]
    endwhile
    call clearmatches()
    let s:colored = 0
    augroup ColorSyntaxHighlight
      au!
    augroup END
endfunction

command! ColorSyntaxHighlightToggle call ColorSyntaxHighlightToggle()
command! ColorSyntaxHighlightOn call ColorSyntaxHighlightOn()
command! ColorSyntaxHighlightClear call ColorSyntaxHighlightClear()

map <Leader><F2> :call ColorSyntaxHighlightToggle()<Return>
