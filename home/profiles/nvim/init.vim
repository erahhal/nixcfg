" -----------------------------------------------------
" Notes
" -----------------------------------------------------

" :help     - Help for VIM
" ctrl-]    - Go to section in VIM help
"
" Motion
" --------
" http://vimdoc.sourceforge.net/htmldoc/motion.html
"
" ctrl-o    - back
" ctrl-i    - forward
" :jumps    - history
"
" .         - REPEAT AN OPERATION!
" :retab    - convert tabs to spaces
" gf        - Go to file (e.g. C++ header)
" ^wf       - Go to file in new pane
" ^wgf      - Go to file in new tab
" ~         - Swap case
" g~        - Swap case for <modifier>
" gu        - Lower case
" gU        - Upper case
" %         - Move to matching item for bracket under or after cursor.
" [(        - go to [count] previous unmatched '('.
" [{        - go to [count] previous unmatched '{'.
" ])        - go to [count] next unmatched ')'.
" ]}        - go to [count] next unmatched '}'.
" )         - go [count] sentences forward.
" (         - go [count] sentences backward.
" }         - go [count] paragraphs forward.
" {         - go [count] paragraphs backward.
" ]]        - [count] sections forward or to the next '{' in the first column.
" ][        - [count] sections forward or to the next '}' in the first column.
" [[        - [count] sections backward or to the previous '{' in the first column.
" []        - [count] sections backward or to the previous '}' in the first column.
" ]m        - Go to [count] next start of a method (for Java or similar structured language)
" ]M        - Go to [count] next end of a method (for Java or similar structured language)
" [m        - Go to [count] previous start of a method (for Java or similar structured language)
" [M        - Go to [count] previous end of a method (for Java or similar structured language)
" [* or [/  - go to [count] previous start of a C comment "/*".
" ]* or ]/  - go to [count] next end of a C comment "*/".
" m{a-zA-Z} - Set mark {a-zA-Z} at cursor position
" '{a-zA-Z} - Jump to mark
" m' or m`  - Set the previous context mark.
" '' or ''  - Jump to previous context mark.
" H         - Jump to top of window.
" M         - Jump to middle of window.
" L         - Jump to bottom of window.
" zz        - recenter window.
" :'<,'>    - visual selection as range.  So type : with a selection then do a s/// search/replace
" yiw       - yank word
" yi"       - yank between quotes
" yiW       - yank to surrounding spaces
" viw       - select word under cursor
" viwp      - select word then replace
" vi"p      - select between quotes and replace
" viw"0p    - select word then replace with first selection rather than last replaced word
" :cn       - next in quickfix list
" :cp       - previous in quickfix list
" :copen    - open quickfix list
" :ccl      - close quickfix list
"
" Search and Replace in files
" ---------------------------
" Select files first:
" :args **/*.js
" :args `find . -type f`
"
" then search and replace:
" :argdo %s/search/replace/g
" :bufdo
" :windo
" :tabdo
"
" Using quickfix list, select files:
" :grep blah -r **/*.txt
" (or "ms" search in NERDTree)
"
" then search and replace, save, then close all buffers:
" :cfdo %s/from/to/g | update
" :cfdo :bd

" -----------------------------------------------------
" OS Detection
" -----------------------------------------------------

if has("unix")
    let s:uname = substitute(system("uname -s"), '\n', "", "")
    let s:ubuntu_version = substitute(system("lsb_release -a | grep Release | awk '{ print $2 }'"), '\n', "", "")
else
    let s:uname = 'unknown'
endif

" -----------------------------------------------------
" General settings
" -----------------------------------------------------

let mapleader=" "                       " Set leader
let maplocalleader=" "                  " Set local leader
set nowrap
" set tw=80                               " Text wraping
set ruler
" set number
set mouse-=a
set signcolumn=yes
set foldexpr=nvim_treesitter#foldexpr()

set undodir=~/.config/nvim/undo/
set undofile

" - enables filetype detection,
" - enables filetype-specific scripts (ftplugins),
" - enables filetype-specific indent scripts.
" Things like ctrl-w ctrl-] won't find custom ctag files without this
filetype plugin indent on

if system("echo -n $HOSTNAME") != 'sicmundus' && system("echo -n $HOST") != 'sicmundus'
    "" Messes up colors over mosh, so don't set this for the server
    set termguicolors
endif

" -----------------------------------------------------
" Key mappings
" -----------------------------------------------------

" Next buffer
noremap <Tab> :bn<CR>
" Previous buffer
noremap <S-Tab> :bp<CR>
" Close buffer
noremap <Leader><Tab> :Bw<CR>
noremap <Leader><S-Tab> :Bw!<CR>
" New tab
noremap <Leader>t :tabnew split<CR>

" -----------------------------------------------------
" Inline functions and config
" -----------------------------------------------------

" Have Vim jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" Automatically resize splits when window is resized
augroup AutoResize
    autocmd FocusGained,FocusLost,VimResized * wincmd =
augroup end

" Highlight tabs
fun! HighlightTabs()
    if exists('w:extratabs')
        call matchdelete(w:extratabs)
        unlet w:extratabs
    endif
    highlight ExtraTabs ctermbg=red guibg=red
    if &ft == 'help'
        return
    else
        let w:extratabs=matchadd('ExtraTabs', '\t\+')
    endif
endfun

augroup TabHighlight
    autocmd BufEnter * call HighlightTabs()
augroup END

" Remove trailing whitespace
fun! TrimTrailingWhitespace()
    if &ft =~ 'javascript\|html\|jade\|json\|css\|less\|php\|python\|sh\|c\|cpp\|markdown\|yaml\|vim\|nix'
        :%s/\s\+$//e
    elseif expand('%:t') =~ '\.gltf$' || expand('%:t') =~ '\.glsl$'
        :%s/\s\+$//e
    endif
endfun

augroup WhiteSpaceTrim
    autocmd BufWritePre * call TrimTrailingWhitespace()
augroup END

" Show max line width
fun! ShowMaxLineWidth()
    if &ft =~ 'javascript\|html\|css\|python\|sh\|c\|cpp\|markdown\|yaml\|vim\|nix'
        :set colorcolumn=120
    endif
endfun

augroup MaxLineWidth
    autocmd BufEnter * call ShowMaxLineWidth()
augroup END

" Indented folding
" Modified from http://dhruvasagar.com/2013/03/28/vim-better-foldtext
function! NeatFoldText()
    let indent_level = indent(v:foldstart)
    let indent = repeat(' ',indent_level)
    let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
    let lines_count = v:foldend - v:foldstart + 1
    let lines_count_text = '-' . printf("%10s", lines_count . ' lines') . ' '
    let foldchar = matchstr(&fillchars, 'fold:\zs.')
    let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
    let foldtextend = lines_count_text . repeat(foldchar, 8)
    let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
    return indent . foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
endfunction
set foldtext=NeatFoldText()

" -----------------------------------------------------
" Backspace settings
"   indent  allow backspacing over autoindent
"   eol     allow backspacing over line breaks (join lines)
"   start   allow backspacing over the start of insert; CTRL-W and CTRL-U
"   0     same as ":set backspace=" (Vi compatible)
"   1     same as ":set backspace=indent,eol"
"   2     same as ":set backspace=indent,eol,start"
" -----------------------------------------------------

set bs=2

" -----------------------------------------------------
" Indentation  settings
" -----------------------------------------------------

set tabstop=4       " number of spaces a tab counts for
set shiftwidth=4    " control how many columns text is indented with the reindent operations (<< and >>) and automatic C-style indentation.
set expandtab       " Insert spaces when entering <Tab>
set softtabstop=4   " Number of spaces that a <Tab> counts for while performing editing operations, like inserting a <Tab> or using <BS>.  It "feels" like a tab though
set ai              " auto indent

" -----------------------------------------------------
" Spell checking
" -----------------------------------------------------

setlocal spell spelllang=en_us
" Show nine spell checking candidates at most
set spellsuggest=best,9

augroup SpellCheck
    autocmd BufRead,BufNewFile *.txt setlocal spell
    autocmd BufRead,BufNewFile *.md setlocal spell
augroup END

" -----------------------------------------------------
" Fold settings
"
"   fdm:
"     manual     Folds are created manually.
"     indent     Lines with equal indent form a fold.
"     expr       'foldexpr' gives the fold level of a line.
"     marker     Markers are used to specify folds.
"     syntax     Syntax highlighting items specify folds.
"     diff       Fold text that is not changed.
" -----------------------------------------------------

set fdm=marker
"set foldmethod=indent
"set foldlevelstart=0
" javascript folding doesn't work very well with several levels of nested anonymous functions
"let javaScript_fold=1         " JavaScript
"let php_folding=1             " PHP
let g:vim_markdown_folding_disabled=1

" -----------------------------------------------------
" Huge file handling
" -----------------------------------------------------

" disable syntax highlighting in big files
function DisableSyntaxTreesitter()
    echo("Big file, disabling syntax, treesitter and folding")
    if exists(':TSBufDisable')
        exec 'TSBufDisable autotag'
        exec 'TSBufDisable highlight'
        " etc...
    endif

    set foldmethod=manual
    syntax clear
    syntax off    " hmmm, which one to use?
    filetype off
    set noundofile
    set noswapfile
    set noloadplugins
endfunction

augroup BigFileDisable
    autocmd!
    autocmd BufWinEnter * if getfsize(expand("%")) > 512 * 1024 | exec DisableSyntaxTreesitter() | endif
augroup END

